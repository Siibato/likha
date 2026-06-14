import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:uuid/uuid.dart';

Future<String> createAssessmentWithQuestions(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String classId,
  String title,
  String? description,
  int timeLimitMinutes,
  String openAt,
  String closeAt,
  bool? showResultsImmediately,
  List<QuestionModel> questions,
  bool isPublished,
  String? linkedTosId,
  int? quarter,
  String? component,
) async {
  try {
    final db = await localDatabase.database;
    final assessmentId = const Uuid().v4();
    final now = DateTime.now();

    await db.transaction((txn) async {
      await txn.insert(
        DbTables.assessments,
        {
          CommonCols.id: assessmentId,
          AssessmentsCols.classId: classId,
          AssessmentsCols.title: title,
          if (description != null) AssessmentsCols.description: description,
          AssessmentsCols.timeLimitMinutes: timeLimitMinutes,
          AssessmentsCols.openAt: openAt,
          AssessmentsCols.closeAt: closeAt,
          AssessmentsCols.showResultsImmediately: (showResultsImmediately ?? false) ? 1 : 0,
          AssessmentsCols.resultsReleased: 0,
          AssessmentsCols.isPublished: isPublished ? 1 : 0,
          AssessmentsCols.orderIndex: 0,
          if (linkedTosId != null) AssessmentsCols.tosId: linkedTosId,
          if (quarter != null) AssessmentsCols.gradingPeriodNumber: quarter,
          if (component != null) AssessmentsCols.component: component,
          CommonCols.createdAt: now.toIso8601String(),
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.syncStatus: 'pending',
        },
      );

      for (final question in questions) {
        await txn.insert(
          DbTables.assessmentQuestions,
          {
            CommonCols.id: question.id,
            AssessmentQuestionsCols.assessmentId: assessmentId,
            AssessmentQuestionsCols.questionType: question.questionType,
            AssessmentQuestionsCols.questionText: question.questionText,
            AssessmentQuestionsCols.points: question.points,
            AssessmentQuestionsCols.orderIndex: question.orderIndex,
            AssessmentQuestionsCols.isMultiSelect: question.isMultiSelect ? 1 : 0,
            CommonCols.createdAt: now.toIso8601String(),
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.syncStatus: 'pending',
          },
        );

        if (question.choices != null) {
          for (final choice in question.choices!) {
            await txn.insert(
              DbTables.questionChoices,
              {
                CommonCols.id: choice.id,
                QuestionChoicesCols.questionId: question.id,
                QuestionChoicesCols.choiceText: choice.choiceText,
                QuestionChoicesCols.isCorrect: choice.isCorrect ? 1 : 0,
                QuestionChoicesCols.orderIndex: choice.orderIndex,
                CommonCols.cachedAt: now.toIso8601String(),
                CommonCols.syncStatus: 'synced',
              },
            );
          }
        }

        if (question.correctAnswers != null && question.correctAnswers!.isNotEmpty) {
          final answerKeyId = const Uuid().v4();
          await txn.insert(
            DbTables.answerKeys,
            {
              CommonCols.id: answerKeyId,
              AnswerKeysCols.questionId: question.id,
              AnswerKeysCols.itemType: DbValues.itemTypeCorrectAnswer,
              CommonCols.cachedAt: now.toIso8601String(),
              CommonCols.syncStatus: 'synced',
            },
          );

          for (final answer in question.correctAnswers!) {
            await txn.insert(
              DbTables.answerKeyAcceptableAnswers,
              {
                CommonCols.id: answer.id,
                AnswerKeyAcceptableAnswersCols.answerKeyId: answerKeyId,
                AnswerKeyAcceptableAnswersCols.answerText: answer.answerText,
                CommonCols.cachedAt: now.toIso8601String(),
                CommonCols.syncStatus: 'synced',
              },
            );
          }
        }

        if (question.enumerationItems != null && question.enumerationItems!.isNotEmpty) {
          for (final enumItem in question.enumerationItems!) {
            final answerKeyId = const Uuid().v4();
            await txn.insert(
              DbTables.answerKeys,
              {
                CommonCols.id: answerKeyId,
                AnswerKeysCols.questionId: question.id,
                AnswerKeysCols.itemType: DbValues.itemTypeEnumerationItem,
                CommonCols.cachedAt: now.toIso8601String(),
                CommonCols.syncStatus: 'synced',
              },
            );

            for (final acceptableAnswer in enumItem.acceptableAnswers) {
              await txn.insert(
                DbTables.answerKeyAcceptableAnswers,
                {
                  CommonCols.id: acceptableAnswer.id,
                  AnswerKeyAcceptableAnswersCols.answerKeyId: answerKeyId,
                  AnswerKeyAcceptableAnswersCols.answerText: acceptableAnswer.answerText,
                  CommonCols.cachedAt: now.toIso8601String(),
                  CommonCols.syncStatus: 'synced',
                },
              );
            }
          }
        }
      }

      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.create,
          payload: {
            'id': assessmentId,
            'class_id': classId,
            'title': title,
            if (description != null) 'description': description,
            'time_limit_minutes': timeLimitMinutes,
            'open_at': openAt,
            'close_at': closeAt,
            if (showResultsImmediately != null) 'show_results_immediately': showResultsImmediately,
            'is_published': isPublished,
            if (quarter != null) 'quarter': quarter,
            if (component != null) 'component': component,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ),
        txn: txn,
      );

      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.question,
          operation: SyncOperation.create,
          payload: {
            'assessment_id': assessmentId,
            'questions': questions.map((q) {
              final map = <String, dynamic>{
                'id': q.id,
                'question_type': q.questionType,
                'question_text': q.questionText,
                'points': q.points,
                'order_index': q.orderIndex,
              };
              if (q.isMultiSelect) map['is_multi_select'] = true;
              if (q.choices != null) {
                map['choices'] = q.choices!.map((c) => {
                      'id': c.id,
                      'choice_text': c.choiceText,
                      'is_correct': c.isCorrect,
                      'order_index': c.orderIndex,
                    }).toList();
              }
              if (q.correctAnswers != null) {
                map['correct_answers'] = q.correctAnswers!.map((a) => {
                      'id': a.id,
                      'answer_text': a.answerText,
                    }).toList();
              }
              if (q.enumerationItems != null) {
                map['enumeration_items'] = q.enumerationItems!.map((e) => {
                      'id': e.id,
                      'order_index': e.orderIndex,
                      'acceptable_answers': e.acceptableAnswers.map((a) => {
                            'id': a.id,
                            'answer_text': a.answerText,
                          }).toList(),
                    }).toList();
              }
              return map;
            }).toList(),
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now.add(const Duration(milliseconds: 1)),
        ),
        txn: txn,
      );
    });

    final assessmentVerify = await db.query(
      'assessments',
      where: '${CommonCols.id} = ?',
      whereArgs: [assessmentId],
      limit: 1,
    );

    if (assessmentVerify.isEmpty) {
      throw CacheException('Failed to verify assessment creation: assessment not found in database');
    }

    final questionsCount = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${DbTables.assessmentQuestions} WHERE assessment_id = ?',
      [assessmentId],
    );
    final insertedQuestionCount = (questionsCount.first['cnt'] as num).toInt();

    if (insertedQuestionCount != questions.length) {
      throw CacheException(
        'Failed to verify question insertion: expected ${questions.length} questions, '
        'but only found $insertedQuestionCount in database'
      );
    }

    return assessmentId;
  } catch (e) {
    throw CacheException('Failed to create assessment with questions locally: $e');
  }
}
