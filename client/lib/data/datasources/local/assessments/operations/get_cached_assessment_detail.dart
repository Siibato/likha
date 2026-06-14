import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';

Future<(AssessmentModel, List<QuestionModel>)> getCachedAssessmentDetail(
  LocalDatabase localDatabase,
  String assessmentId,
) async {
  try {
    final db = await localDatabase.database;
    final assessmentResults = await db.query(
      DbTables.assessments,
      where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [assessmentId],
    );
    if (assessmentResults.isEmpty) throw CacheException('Assessment $assessmentId not cached');

    final assessment = AssessmentModel.fromMap(assessmentResults.first);
    final questionResults = await db.query(
      DbTables.assessmentQuestions,
      where: '${AssessmentQuestionsCols.assessmentId} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [assessmentId],
      orderBy: '${AssessmentQuestionsCols.orderIndex} ASC',
    );

    final questions = <QuestionModel>[];
    for (final q in questionResults) {
      final questionId = q['id'] as String;

      final choicesResults = await db.query(
        DbTables.questionChoices,
        where: '${QuestionChoicesCols.questionId} = ?',
        whereArgs: [questionId],
        orderBy: '${QuestionChoicesCols.orderIndex} ASC',
      );

      final choices = choicesResults.map((c) {
        return {
          'id': c['id'],
          'choice_text': c['choice_text'],
          'is_correct': (c['is_correct'] as int?) == 1,
          'order_index': c['order_index'],
        };
      }).toList();

      final answerKeysResults = await db.query(
        DbTables.answerKeys,
        columns: [CommonCols.id, AnswerKeysCols.itemType],
        where: '${AnswerKeysCols.questionId} = ?',
        whereArgs: [questionId],
      );

      final correctAnswers = <Map<String, dynamic>>[];
      final enumerationItems = <Map<String, dynamic>>[];

      for (final answerKey in answerKeysResults) {
        final answerKeyId = answerKey['id'] as String;
        final itemType = answerKey['item_type'] as String? ?? 'correct_answer';
        final acceptableAnswersResults = await db.query(
          DbTables.answerKeyAcceptableAnswers,
          where: '${AnswerKeyAcceptableAnswersCols.answerKeyId} = ?',
          whereArgs: [answerKeyId],
        );

        if (itemType == DbValues.itemTypeEnumerationItem) {
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
          for (final answer in acceptableAnswersResults) {
            correctAnswers.add({
              'id': answer['id'],
              'answer_text': answer['answer_text'],
            });
          }
        }
      }

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

    final computedTotalPoints = questions.fold(0, (sum, q) => sum + q.points);

    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbTables.assessmentSubmissions} WHERE assessment_id = ? AND deleted_at IS NULL',
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
      syncStatus: assessment.syncStatus,
      deletedAt: assessment.deletedAt,
    );

    return (updatedAssessment, questions);
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}
