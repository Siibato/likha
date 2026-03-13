import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../assessment_local_datasource_base.dart';

mixin AssessmentCacheMixin on AssessmentLocalDataSourceBase {
  @override
  Future<void> cacheAssessments(List<AssessmentModel> assessments) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        for (final assessment in assessments) {
          final map = assessment.toMap();
          map['cached_at'] = DateTime.now().toIso8601String();
          map['needs_sync'] = 0;
          await txn.insert('assessments', map, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache assessments: $e');
    }
  }

  @override
  Future<void> cacheAssessmentDetail(AssessmentModel assessment, List<QuestionModel> questions) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        final assessmentMap = assessment.toMap();
        assessmentMap['cached_at'] = DateTime.now().toIso8601String();
        assessmentMap['needs_sync'] = 0;
        await txn.insert('assessments', assessmentMap, conflictAlgorithm: ConflictAlgorithm.replace);

        for (final question in questions) {
          final now = DateTime.now().toIso8601String();
          // Delete stale child rows before re-inserting (prevents orphan accumulation)
          await txn.delete('answer_keys', where: 'question_id = ?', whereArgs: [question.id]);
          await txn.delete('question_choices', where: 'question_id = ?', whereArgs: [question.id]);

          // Insert assessment_questions (v18 - renamed from 'questions')
          await txn.insert(
            'assessment_questions',
            {
              'id': question.id,
              'assessment_id': assessment.id,
              'question_type': question.questionType,
              'question_text': question.questionText,
              'points': question.points,
              'order_index': question.orderIndex,
              'is_multi_select': question.isMultiSelect ? 1 : 0,
              'created_at': question.createdAt?.toIso8601String() ?? now,
              'updated_at': question.updatedAt?.toIso8601String() ?? now,
              'cached_at': now,
              'needs_sync': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
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
                  'cached_at': now,
                  'needs_sync': 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }

          // Normalize correct answers into answer_keys and answer_key_acceptable_answers
          if (question.correctAnswers != null && question.correctAnswers!.isNotEmpty) {
            // Use stable ID for correctAnswers (composite ID)
            final answerKeyId = '${question.id}_correct_key';
            await txn.insert(
              'answer_keys',
              {
                'id': answerKeyId,
                'question_id': question.id,
                'item_type': 'correct_answer',
                'cached_at': now,
                'needs_sync': 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            // Insert acceptable answers
            for (final answer in question.correctAnswers!) {
              await txn.insert(
                'answer_key_acceptable_answers',
                {
                  'id': answer.id,
                  'answer_key_id': answerKeyId,
                  'answer_text': answer.answerText,
                  'cached_at': now,
                  'needs_sync': 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }

          // Normalize enumeration items into answer_keys and answer_key_acceptable_answers
          if (question.enumerationItems != null && question.enumerationItems!.isNotEmpty) {
            for (final enumItem in question.enumerationItems!) {
              // Use server ID for enumeration items
              final answerKeyId = enumItem.id;
              await txn.insert(
                'answer_keys',
                {
                  'id': answerKeyId,
                  'question_id': question.id,
                  'item_type': 'enumeration_item',
                  'cached_at': now,
                  'needs_sync': 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              // Insert acceptable answers for this enumeration item
              for (final acceptableAnswer in enumItem.acceptableAnswers) {
                await txn.insert(
                  'answer_key_acceptable_answers',
                  {
                    'id': acceptableAnswer.id,
                    'answer_key_id': answerKeyId,
                    'answer_text': acceptableAnswer.answerText,
                    'cached_at': now,
                    'needs_sync': 0,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
          }
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache assessment detail: $e');
    }
  }

  @override
  Future<void> cacheQuestions(
    String assessmentId,
    List<QuestionModel> questions, {
    bool isServerConfirmed = false,
  }) async {
    try {
      final db = await localDatabase.database;

      // Verify assessment exists before inserting questions (FK constraint check)
      final assessmentExists = await db.rawQuery(
        'SELECT id FROM assessments WHERE id = ? LIMIT 1',
        [assessmentId],
      );

      if (assessmentExists.isEmpty) {
        throw CacheException(
          'Assessment with ID $assessmentId not found in database. '
          'Cannot insert questions without a valid assessment reference.'
        );
      }

      await db.transaction((txn) async {
        for (final question in questions) {
          final now = DateTime.now().toIso8601String();
          // Delete stale child rows before re-inserting (prevents orphan accumulation)
          await txn.delete('answer_keys', where: 'question_id = ?', whereArgs: [question.id]);
          await txn.delete('question_choices', where: 'question_id = ?', whereArgs: [question.id]);

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
              'created_at': question.createdAt?.toIso8601String() ?? now,
              'updated_at': question.updatedAt?.toIso8601String() ?? now,
              'cached_at': now,
              'needs_sync': isServerConfirmed ? 0 : 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Normalize choices
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
                  'cached_at': now,
                  'needs_sync': 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }

          // Normalize correct answers
          if (question.correctAnswers != null && question.correctAnswers!.isNotEmpty) {
            final answerKeyId = '${question.id}_correct_key';
            await txn.insert(
              'answer_keys',
              {
                'id': answerKeyId,
                'question_id': question.id,
                'item_type': 'correct_answer',
                'cached_at': now,
                'needs_sync': 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            for (final answer in question.correctAnswers!) {
              await txn.insert(
                'answer_key_acceptable_answers',
                {
                  'id': answer.id,
                  'answer_key_id': answerKeyId,
                  'answer_text': answer.answerText,
                  'cached_at': now,
                  'needs_sync': 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }

          // Normalize enumeration items
          if (question.enumerationItems != null && question.enumerationItems!.isNotEmpty) {
            for (final enumItem in question.enumerationItems!) {
              final answerKeyId = enumItem.id;
              await txn.insert(
                'answer_keys',
                {
                  'id': answerKeyId,
                  'question_id': question.id,
                  'item_type': 'enumeration_item',
                  'cached_at': now,
                  'needs_sync': 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              for (final acceptableAnswer in enumItem.acceptableAnswers) {
                await txn.insert(
                  'answer_key_acceptable_answers',
                  {
                    'id': acceptableAnswer.id,
                    'answer_key_id': answerKeyId,
                    'answer_text': acceptableAnswer.answerText,
                    'cached_at': now,
                    'needs_sync': 0,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
          }
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache questions: $e');
    }
  }

  @override
  Future<void> releaseResultsLocally({required String assessmentId}) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.update(
          'assessments',
          {
            'results_released': 1,
            'needs_sync': 1,
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [assessmentId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.releaseResults,
          payload: {'id': assessmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to release results locally: $e');
    }
  }

  @override
  Future<void> deleteAssessmentLocally({required String assessmentId}) async {
    try {
      final db = await localDatabase.database;
      await db.update(
        'assessments',
        {
          'deleted_at': DateTime.now().toIso8601String(),
          'needs_sync': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [assessmentId],
      );
    } catch (e) {
      throw CacheException('Failed to delete assessment locally: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      final db = await localDatabase.database;
      await db.delete('assessments');
      await db.delete('assessment_questions');
      await db.delete('question_choices');
      await db.delete('answer_keys');
      await db.delete('answer_key_acceptable_answers');
      await db.delete('submission_answers');
      await db.delete('submission_answer_items');
      await db.delete('assessment_submissions');
    } catch (e) {
      throw CacheException('Failed to clear assessment cache: $e');
    }
  }
}
