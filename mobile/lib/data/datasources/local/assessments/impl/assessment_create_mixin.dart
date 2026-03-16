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
  }) async {
    try {
      final db = await localDatabase.database;
      final assessmentId = const Uuid().v4();
      final now = DateTime.now();

      await db.transaction((txn) async {
        await txn.insert(
          'assessments',
          {
            'id': assessmentId,
            'class_id': classId,
            'title': title,
            if (description != null) 'description': description,
            'time_limit_minutes': timeLimitMinutes,
            'open_at': openAt,
            'close_at': closeAt,
            'show_results_immediately': (showResultsImmediately ?? false) ? 1 : 0,
            'results_released': 0,
            'is_published': isPublished ? 1 : 0,
            'order_index': 0,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
            'needs_sync': 1,
          },
        );

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
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 3,
            createdAt: now,
          ),
          txn: txn,
        );
      });

      // Verify assessment was actually inserted
      final verifyResult = await db.query(
        'assessments',
        where: 'id = ?',
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
  }) async {
    try {
      final db = await localDatabase.database;
      final assessmentId = const Uuid().v4();
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Step 1: Create assessment
        await txn.insert(
          'assessments',
          {
            'id': assessmentId,
            'class_id': classId,
            'title': title,
            if (description != null) 'description': description,
            'time_limit_minutes': timeLimitMinutes,
            'open_at': openAt,
            'close_at': closeAt,
            'show_results_immediately': (showResultsImmediately ?? false) ? 1 : 0,
            'results_released': 0,
            'is_published': isPublished ? 1 : 0,
            'order_index': 0,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
            'needs_sync': 1,
          },
        );

        // Step 2: Cache all questions in the same transaction
        for (final question in questions) {
          // Insert into assessment_questions (v18 - renamed from 'questions')
          await txn.insert(
            'assessment_questions',
            {
              'id': question.id,
              'assessment_id': assessmentId,
              'question_type': question.questionType,
              'question_text': question.questionText,
              'points': question.points,
              'order_index': question.orderIndex,
              'is_multi_select': question.isMultiSelect ? 1 : 0,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
              'cached_at': now.toIso8601String(),
              'needs_sync': 1,
            },
          );

          // Normalize choices into question_choices table
          if (question.choices != null) {
            for (final choice in question.choices!) {
              await txn.insert(
                'question_choices',
                {
                  'id': choice.id,
                  'question_id': question.id,
                  'choice_text': choice.choiceText,
                  'is_correct': choice.isCorrect ? 1 : 0,
                  'order_index': choice.orderIndex,
                  'cached_at': now.toIso8601String(),
                  'needs_sync': 0,
                },
              );
            }
          }

          // Normalize correct answers
          if (question.correctAnswers != null && question.correctAnswers!.isNotEmpty) {
            final answerKeyId = const Uuid().v4();
            await txn.insert(
              'answer_keys',
              {
                'id': answerKeyId,
                'question_id': question.id,
                'item_type': 'correct_answer',
                'cached_at': now.toIso8601String(),
                'needs_sync': 0,
              },
            );

            for (final answer in question.correctAnswers!) {
              await txn.insert(
                'answer_key_acceptable_answers',
                {
                  'id': answer.id,
                  'answer_key_id': answerKeyId,
                  'answer_text': answer.answerText,
                  'cached_at': now.toIso8601String(),
                  'needs_sync': 0,
                },
              );
            }
          }

          // Normalize enumeration items
          if (question.enumerationItems != null && question.enumerationItems!.isNotEmpty) {
            for (final enumItem in question.enumerationItems!) {
              final answerKeyId = const Uuid().v4();
              await txn.insert(
                'answer_keys',
                {
                  'id': answerKeyId,
                  'question_id': question.id,
                  'item_type': 'enumeration_item',
                  'cached_at': now.toIso8601String(),
                  'needs_sync': 0,
                },
              );

              for (final acceptableAnswer in enumItem.acceptableAnswers) {
                await txn.insert(
                  'answer_key_acceptable_answers',
                  {
                    'id': acceptableAnswer.id,
                    'answer_key_id': answerKeyId,
                    'answer_text': acceptableAnswer.answerText,
                    'cached_at': now.toIso8601String(),
                    'needs_sync': 0,
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
        where: 'id = ?',
        whereArgs: [assessmentId],
        limit: 1,
      );

      if (assessmentVerify.isEmpty) {
        throw CacheException('Failed to verify assessment creation: assessment not found in database');
      }

      final questionsCount = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM assessment_questions WHERE assessment_id = ?',
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
          'is_published': 1,
          'updated_at': DateTime.now().toIso8601String(),
          'cached_at': DateTime.now().toIso8601String(),
          'needs_sync': 1,
        },
        where: 'id = ?',
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
          'is_published': 0,
          'updated_at': DateTime.now().toIso8601String(),
          'cached_at': DateTime.now().toIso8601String(),
          'needs_sync': 1,
        },
        where: 'id = ?',
        whereArgs: [assessmentId],
      );
    } catch (e) {
      throw CacheException('Failed to mark assessment as unpublished locally: $e');
    }
  }
}
