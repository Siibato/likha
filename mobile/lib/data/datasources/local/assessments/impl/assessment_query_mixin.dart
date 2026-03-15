import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import '../assessment_local_datasource_base.dart';

mixin AssessmentQueryMixin on AssessmentLocalDataSourceBase {
  @override
  Future<List<AssessmentModel>> getCachedAssessments(String classId, {bool publishedOnly = false}) async {
    try {
      final db = await localDatabase.database;
      final where = publishedOnly
          ? 'class_id = ? AND is_published = 1 AND deleted_at IS NULL'
          : 'class_id = ? AND deleted_at IS NULL';
      final results = await db.query(
        'assessments',
        where: where,
        whereArgs: [classId],
        orderBy: 'order_index ASC',
      );
      if (results.isEmpty) return [];

      final assessments = <AssessmentModel>[];

      // Compute actual question count and total points from the assessment_questions table for each assessment
      for (final result in results) {
        final assessment = AssessmentModel.fromMap(result);
        final statsResult = await db.rawQuery(
          'SELECT COUNT(*) as count, SUM(points) as total_points FROM assessment_questions WHERE assessment_id = ? AND deleted_at IS NULL',
          [assessment.id],
        );
        final actualCount = statsResult.first['count'] as int? ?? 0;
        final computedTotalPoints = statsResult.first['total_points'] as int? ?? 0;

        final subCountResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM assessment_submissions WHERE assessment_id = ? AND deleted_at IS NULL',
          [assessment.id],
        );
        final liveSubCount = subCountResult.first['count'] as int? ?? 0;
        final effectiveSubCount = liveSubCount > 0 ? liveSubCount : assessment.submissionCount;

        final effectiveTotalPoints = computedTotalPoints > 0 ? computedTotalPoints : assessment.totalPoints;

        final updatedAssessment = AssessmentModel(
          id: assessment.id,
          classId: assessment.classId,
          title: assessment.title,
          description: assessment.description,
          timeLimitMinutes: assessment.timeLimitMinutes,
          openAt: assessment.openAt,
          closeAt: assessment.closeAt,
          showResultsImmediately: assessment.showResultsImmediately,
          resultsReleased: assessment.resultsReleased,
          isPublished: assessment.isPublished,
          orderIndex: assessment.orderIndex,
          totalPoints: effectiveTotalPoints,
          questionCount: actualCount > 0 ? actualCount : assessment.questionCount,
          submissionCount: effectiveSubCount,
          createdAt: assessment.createdAt,
          updatedAt: assessment.updatedAt,
          cachedAt: assessment.cachedAt,
          needsSync: assessment.needsSync,
          deletedAt: assessment.deletedAt,
        );
        assessments.add(updatedAssessment);
      }

      return assessments;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<(AssessmentModel, List<QuestionModel>)> getCachedAssessmentDetail(String assessmentId) async {
    try {
      final db = await localDatabase.database;
      final assessmentResults = await db.query(
        'assessments',
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [assessmentId],
      );
      if (assessmentResults.isEmpty) throw CacheException('Assessment $assessmentId not cached');

      final assessment = AssessmentModel.fromMap(assessmentResults.first);
      final questionResults = await db.query(
        'assessment_questions',
        where: 'assessment_id = ? AND deleted_at IS NULL',
        whereArgs: [assessmentId],
        orderBy: 'order_index ASC',
      );

      final questions = <QuestionModel>[];
      for (final q in questionResults) {
        final questionId = q['id'] as String;

        // Fetch choices for this question
        final choicesResults = await db.query(
          'question_choices',
          where: 'question_id = ?',
          whereArgs: [questionId],
          orderBy: 'order_index ASC',
        );

        final choices = choicesResults.map((c) {
          return {
            'id': c['id'],
            'choice_text': c['choice_text'],
            'is_correct': (c['is_correct'] as int?) == 1,
            'order_index': c['order_index'],
          };
        }).toList();

        // Fetch answer keys and acceptable answers for this question
        final answerKeysResults = await db.query(
          'answer_keys',
          columns: ['id', 'item_type'],
          where: 'question_id = ?',
          whereArgs: [questionId],
        );

        final correctAnswers = <Map<String, dynamic>>[];
        final enumerationItems = <Map<String, dynamic>>[];

        for (final answerKey in answerKeysResults) {
          final answerKeyId = answerKey['id'] as String;
          final itemType = answerKey['item_type'] as String? ?? 'correct_answer';
          final acceptableAnswersResults = await db.query(
            'answer_key_acceptable_answers',
            where: 'answer_key_id = ?',
            whereArgs: [answerKeyId],
          );

          if (itemType == 'enumeration_item') {
            // Always include enumeration items — students have no acceptable_answers, but count is still needed
            enumerationItems.add({
              'id': answerKeyId,
              'order_index': enumerationItems.length,
              'acceptable_answers': acceptableAnswersResults.map((aa) {
                return {
                  'id': aa['id'],
                  'answer_text': aa['answer_text'],
                };
              }).toList(),
            });
          } else if (acceptableAnswersResults.isNotEmpty) {
            // correct_answer: flatten all acceptable answers as CorrectAnswer objects
            for (final answer in acceptableAnswersResults) {
              correctAnswers.add({
                'id': answer['id'],
                'answer_text': answer['answer_text'],
              });
            }
          }
        }

        // Build question data map for fromJson
        final questionData = {
          'id': q['id'],
          'assessment_id': q['assessment_id'],
          'question_type': q['question_type'],
          'question_text': q['question_text'],
          'points': q['points'],
          'order_index': q['order_index'],
          'is_multi_select': (q['is_multi_select'] as int?) == 1,
          'choices': choices.isEmpty ? null : choices,
          'correct_answers': correctAnswers.isEmpty ? null : correctAnswers,
          'enumeration_items': enumerationItems.isEmpty ? null : enumerationItems,
        };

        questions.add(QuestionModel.fromJson(questionData));
      }

      // Create new assessment with the actual question count and computed total points
      final computedTotalPoints = questions.fold(0, (sum, q) => sum + q.points);

      // Compute dynamic submission count from submissions table (E9: fixes stale cache guard)
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM assessment_submissions WHERE assessment_id = ? AND deleted_at IS NULL',
        [assessmentId],
      );
      final liveSubmissionCount = (countResult.first['count'] as int?) ?? 0;

      final updatedAssessment = AssessmentModel(
        id: assessment.id,
        classId: assessment.classId,
        title: assessment.title,
        description: assessment.description,
        timeLimitMinutes: assessment.timeLimitMinutes,
        openAt: assessment.openAt,
        closeAt: assessment.closeAt,
        showResultsImmediately: assessment.showResultsImmediately,
        resultsReleased: assessment.resultsReleased,
        isPublished: assessment.isPublished,
        orderIndex: assessment.orderIndex,
        totalPoints: computedTotalPoints,
        questionCount: questions.length,
        submissionCount: liveSubmissionCount,
        createdAt: assessment.createdAt,
        updatedAt: assessment.updatedAt,
        cachedAt: assessment.cachedAt,
        needsSync: assessment.needsSync,
        deletedAt: assessment.deletedAt,
      );

      return (updatedAssessment, questions);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }
}
