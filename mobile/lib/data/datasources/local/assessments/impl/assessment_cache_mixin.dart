import 'dart:convert';
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
          map['sync_status'] = 'synced';
          map['is_offline_mutation'] = 0;
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
        assessmentMap['sync_status'] = 'synced';
        assessmentMap['is_offline_mutation'] = 0;
        await txn.insert('assessments', assessmentMap, conflictAlgorithm: ConflictAlgorithm.replace);

        for (final question in questions) {
          final now = DateTime.now().toIso8601String();
          await txn.insert(
            'questions',
            {
              'id': question.id,
              'assessment_id': assessment.id,
              'question_type': question.questionType,
              'question_text': question.questionText,
              'points': question.points,
              'order_index': question.orderIndex,
              'is_multi_select': question.isMultiSelect ? 1 : 0,
              'choices_json': question.choices != null
                  ? jsonEncode(question.choices?.map((c) => {
                        'id': c.id,
                        'choice_text': c.choiceText,
                        'is_correct': c.isCorrect,
                        'order_index': c.orderIndex,
                      }).toList())
                  : null,
              'correct_answers_json': question.correctAnswers != null
                  ? jsonEncode(question.correctAnswers?.map((a) => {
                        'id': a.id,
                        'answer_text': a.answerText,
                      }).toList())
                  : null,
              'enumeration_items_json': question.enumerationItems != null
                  ? jsonEncode(question.enumerationItems)
                  : null,
              'updated_at': now,
              'deleted_at': null,
              'cached_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
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
      // This ensures the transaction can see the assessment record
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
              'updated_at': now,
              'cached_at': now,
              'is_offline_mutation': isServerConfirmed ? 0 : 1,
              'sync_status': isServerConfirmed ? 'synced' : 'pending',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
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
            'is_offline_mutation': 1,
            'sync_status': 'pending',
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
          maxRetries: 5,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to release results locally: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      final db = await localDatabase.database;
      await db.delete('assessments');
      await db.delete('questions');
      await db.delete('assessment_submissions');
      await db.delete('assessment_statistics_cache');
      await db.delete('student_results_cache');
    } catch (e) {
      throw CacheException('Failed to clear assessment cache: $e');
    }
  }
}