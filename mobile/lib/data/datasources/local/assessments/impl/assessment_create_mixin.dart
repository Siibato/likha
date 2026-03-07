import 'dart:convert';
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
            'local_id': assessmentId,
            'class_id': classId,
            'title': title,
            if (description != null) 'description': description,
            'time_limit_minutes': timeLimitMinutes,
            'open_at': openAt,
            'close_at': closeAt,
            'show_results_immediately': (showResultsImmediately ?? false) ? 1 : 0,
            'results_released': 0,
            'is_published': 0,
            'total_points': 0,
            'question_count': 0,
            'submission_count': 0,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
            'sync_status': 'pending',
            'is_offline_mutation': 1,
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
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
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
            'local_id': assessmentId,
            'class_id': classId,
            'title': title,
            if (description != null) 'description': description,
            'time_limit_minutes': timeLimitMinutes,
            'open_at': openAt,
            'close_at': closeAt,
            'show_results_immediately': (showResultsImmediately ?? false) ? 1 : 0,
            'results_released': 0,
            'is_published': 0,
            'total_points': 0,
            'question_count': 0,
            'submission_count': 0,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
            'sync_status': 'pending',
            'is_offline_mutation': 1,
          },
        );

        // Step 2: Cache all questions in the same transaction
        for (final question in questions) {
          await txn.insert(
            'questions',
            {
              'id': question.id,
              'local_id': question.id,
              'assessment_id': assessmentId,
              'question_type': question.questionType,
              'question_text': question.questionText,
              'points': question.points,
              'order_index': question.orderIndex,
              'is_multi_select': question.isMultiSelect ? 1 : 0,
              'choices_json': question.choices != null
                  ? jsonEncode(question.choices!.map((c) => {
                        'id': c.id,
                        'choice_text': c.choiceText,
                        'is_correct': c.isCorrect,
                        'order_index': c.orderIndex,
                      }).toList())
                  : null,
              'correct_answers_json': question.correctAnswers != null
                  ? jsonEncode(question.correctAnswers!.map((a) => {
                        'id': a.id,
                        'answer_text': a.answerText,
                      }).toList())
                  : null,
              'enumeration_items_json': question.enumerationItems != null
                  ? jsonEncode(question.enumerationItems!.map((e) => {
                        'id': e.id,
                        'order_index': e.orderIndex,
                        'acceptable_answers': e.acceptableAnswers.map((a) => {
                              'id': a.id,
                              'answer_text': a.answerText,
                            }).toList(),
                      }).toList())
                  : null,
              'updated_at': now.toIso8601String(),
              'cached_at': now.toIso8601String(),
              'is_offline_mutation': 1,
              'sync_status': 'pending',
            },
          );
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
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
          txn: txn,
        );

        // Enqueue questions as a single operation
        await syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.question,
            operation: SyncOperation.create,
            payload: {
              'assessment_id': assessmentId,
              'questions': questions.map((q) {
                final map = <String, dynamic>{
                  'question_type': q.questionType,
                  'question_text': q.questionText,
                  'points': q.points,
                  'order_index': q.orderIndex,
                };
                if (q.isMultiSelect) map['is_multi_select'] = true;
                if (q.choices != null) {
                  map['choices'] = q.choices!.map((c) => {
                        'choice_text': c.choiceText,
                        'is_correct': c.isCorrect,
                        'order_index': c.orderIndex,
                      }).toList();
                }
                if (q.correctAnswers != null) {
                  map['correct_answers'] = q.correctAnswers!.map((a) => a.answerText).toList();
                }
                if (q.enumerationItems != null) {
                  map['enumeration_items'] = q.enumerationItems!.map((e) => {
                        'order_index': e.orderIndex,
                        'acceptable_answers': e.acceptableAnswers.map((a) => a.answerText).toList(),
                      }).toList();
                }
                return map;
              }).toList(),
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
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
        'SELECT COUNT(*) as cnt FROM questions WHERE assessment_id = ?',
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
        },
        where: 'id = ?',
        whereArgs: [assessmentId],
      );
    } catch (e) {
      throw CacheException('Failed to mark assessment as published locally: $e');
    }
  }
}