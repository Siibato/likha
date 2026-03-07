import 'dart:convert';
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
        orderBy: 'created_at DESC',
      );
      if (results.isEmpty) throw CacheException('No cached assessments for class $classId');

      final assessments = <AssessmentModel>[];

      // Compute actual question count from the questions table for each assessment
      for (final result in results) {
        final assessment = AssessmentModel.fromMap(result);
        final countResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM questions WHERE assessment_id = ? AND deleted_at IS NULL',
          [assessment.id],
        );
        final actualCount = countResult.first['count'] as int? ?? 0;

        // Create new assessment with the actual count (or fallback to stored count if none cached)
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
          totalPoints: assessment.totalPoints,
          questionCount: actualCount > 0 ? actualCount : assessment.questionCount,
          submissionCount: assessment.submissionCount,
          createdAt: assessment.createdAt,
          updatedAt: assessment.updatedAt,
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
        'questions',
        where: 'assessment_id = ? AND deleted_at IS NULL',
        whereArgs: [assessmentId],
        orderBy: 'order_index ASC',
      );
      final questions = questionResults
          .map((q) {
            final questionData = Map<String, dynamic>.from(q as Map<String, dynamic>);
            // Convert _json suffix columns to proper array keys for fromJson
            if (questionData['choices_json'] != null) {
              try {
                questionData['choices'] = jsonDecode(questionData['choices_json'] as String);
              } catch (_) {}
            }
            if (questionData['correct_answers_json'] != null) {
              try {
                questionData['correct_answers'] = jsonDecode(questionData['correct_answers_json'] as String);
              } catch (_) {}
            }
            if (questionData['enumeration_items_json'] != null) {
              try {
                questionData['enumeration_items'] = jsonDecode(questionData['enumeration_items_json'] as String);
              } catch (_) {}
            }
            return QuestionModel.fromJson(questionData);
          })
          .toList();

      // Create new assessment with the actual question count
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
        totalPoints: assessment.totalPoints,
        questionCount: questions.length,
        submissionCount: assessment.submissionCount,
        createdAt: assessment.createdAt,
        updatedAt: assessment.updatedAt,
      );

      return (updatedAssessment, questions);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }
}