import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:uuid/uuid.dart';
import '../assessment_local_datasource_base.dart';

mixin AssessmentCreateMixin on AssessmentLocalDataSourceBase {
  @override
  Future<String> createAssessmentLocally({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    bool isPublished = true,
    String? tosId,
    int? gradingPeriodNumber,
    String? component,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      final assessmentId = const Uuid().v4();
      await db.transaction((txn) async {
        await txn.insert(DbTables.assessments, {
          CommonCols.id: assessmentId,
          AssessmentsCols.classId: classId,
          AssessmentsCols.title: title,
          AssessmentsCols.description: description,
          AssessmentsCols.timeLimitMinutes: timeLimitMinutes,
          AssessmentsCols.openAt: openAt,
          AssessmentsCols.closeAt: closeAt,
          AssessmentsCols.showResultsImmediately: showResultsImmediately == true ? 1 : 0,
          AssessmentsCols.resultsReleased: 0,
          AssessmentsCols.isPublished: isPublished ? 1 : 0,
          AssessmentsCols.orderIndex: 0,
          if (tosId != null) AssessmentsCols.tosId: tosId,
          if (gradingPeriodNumber != null) AssessmentsCols.gradingPeriodNumber: gradingPeriodNumber,
          if (component != null) AssessmentsCols.component: component,
          CommonCols.createdAt: now.toIso8601String(),
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
        });

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
              if (tosId != null) 'tos_id': tosId,
              if (gradingPeriodNumber != null) 'grading_period_number': gradingPeriodNumber,
              if (component != null) 'component': component,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 3,
            createdAt: now,
          ),
          txn: txn,
        );
      });

      final verifyResult = await db.query(
        'assessments',
        where: '${CommonCols.id} = ?',
        whereArgs: [assessmentId],
        limit: 1,
      );

      if (verifyResult.isEmpty) {
        throw CacheException('Failed to verify assessment creation: assessment not found in database');
      }

      return assessmentId;
    } catch (e) {
      throw CacheException('Failed to create assessment locally: $e');
    }
  }

  @override
  Future<String> createAssessmentWithQuestionsLocally({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    required List<QuestionModel> questions,
    bool isPublished = true,
    String? linkedTosId,
    int? quarter,
    String? component,
  }) async {
    try {
      final db = await localDatabase.database;
      final assessmentId = const Uuid().v4();
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Step 1: Create assessment
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
            CommonCols.needsSync: 1,
          },
        );

        // Step 2: Cache all questions in the same transaction
        for (final question in questions) {
          // Insert into assessment_questions (v18 - renamed from 'questions')
          await txn.insert(
            DbTables.assessmentQuestions,
            {
              CommonCols.id: question.id,
              AssessmentQuestionsCols.assessmentId: assessmentId,
              AssessmentQuestionsCols.questionType: question.questionType,
              AssessmentQuestionsCols.questionText: enc.encryptField(question.questionText),
              AssessmentQuestionsCols.points: question.points,
              AssessmentQuestionsCols.orderIndex: question.orderIndex,
              AssessmentQuestionsCols.isMultiSelect: question.isMultiSelect ? 1 : 0,
              CommonCols.createdAt: now.toIso8601String(),
              CommonCols.updatedAt: now.toIso8601String(),
              CommonCols.cachedAt: now.toIso8601String(),
              CommonCols.needsSync: 1,
            },
          );

          // Normalize choices into question_choices table
          if (question.choices != null) {
            for (final choice in question.choices!) {
              await txn.insert(
                DbTables.questionChoices,
                {
                  CommonCols.id: choice.id,
                  QuestionChoicesCols.questionId: question.id,
                  QuestionChoicesCols.choiceText: enc.encryptField(choice.choiceText),
                  QuestionChoicesCols.isCorrect: choice.isCorrect ? 1 : 0,
                  QuestionChoicesCols.orderIndex: choice.orderIndex,
                  CommonCols.cachedAt: now.toIso8601String(),
                  CommonCols.needsSync: 0,
                },
              );
            }
          }

          // Normalize correct answers
          if (question.correctAnswers != null && question.correctAnswers!.isNotEmpty) {
            final answerKeyId = const Uuid().v4();
            await txn.insert(
              DbTables.answerKeys,
              {
                CommonCols.id: answerKeyId,
                AnswerKeysCols.questionId: question.id,
                AnswerKeysCols.itemType: DbValues.itemTypeCorrectAnswer,
                CommonCols.cachedAt: now.toIso8601String(),
                CommonCols.needsSync: 0,
              },
            );

            for (final answer in question.correctAnswers!) {
              await txn.insert(
                DbTables.answerKeyAcceptableAnswers,
                {
                  CommonCols.id: answer.id,
                  AnswerKeyAcceptableAnswersCols.answerKeyId: answerKeyId,
                  AnswerKeyAcceptableAnswersCols.answerText: enc.encryptField(answer.answerText),
                  CommonCols.cachedAt: now.toIso8601String(),
                  CommonCols.needsSync: 0,
                },
              );
            }
          }

          // Normalize enumeration items
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
                  CommonCols.needsSync: 0,
                },
              );

              for (final acceptableAnswer in enumItem.acceptableAnswers) {
                await txn.insert(
                  DbTables.answerKeyAcceptableAnswers,
                  {
                    CommonCols.id: acceptableAnswer.id,
                    AnswerKeyAcceptableAnswersCols.answerKeyId: answerKeyId,
                    AnswerKeyAcceptableAnswersCols.answerText: enc.encryptField(acceptableAnswer.answerText),
                    CommonCols.cachedAt: now.toIso8601String(),
                    CommonCols.needsSync: 0,
                  },
                );
              }
            }
          }
        }

        // Step 3: Enqueue sync operations for both assessment and questions
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

        // Enqueue questions as a single operation with client-generated IDs (matching addQuestions pattern)
        // Use createdAt + 1ms to ensure questions are processed AFTER assessment on the server
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

      // Verify both assessment and questions were actually inserted
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

  @override
  Future<void> markAssessmentPublishedLocally({required String assessmentId}) async {
    try {
      final db = await localDatabase.database;
      await db.update(
        'assessments',
        {
          AssessmentsCols.isPublished: 1,
          CommonCols.updatedAt: DateTime.now().toIso8601String(),
          CommonCols.cachedAt: DateTime.now().toIso8601String(),
          CommonCols.needsSync: 1,
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [assessmentId],
      );
    } catch (e) {
      throw CacheException('Failed to mark assessment as published locally: $e');
    }
  }

  @override
  Future<void> markAssessmentUnpublishedLocally({required String assessmentId}) async {
    try {
      final db = await localDatabase.database;
      await db.update(
        'assessments',
        {
          AssessmentsCols.isPublished: 0,
          CommonCols.updatedAt: DateTime.now().toIso8601String(),
          CommonCols.cachedAt: DateTime.now().toIso8601String(),
          CommonCols.needsSync: 1,
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [assessmentId],
      );
    } catch (e) {
      throw CacheException('Failed to mark assessment as unpublished locally: $e');
    }
  }
}
