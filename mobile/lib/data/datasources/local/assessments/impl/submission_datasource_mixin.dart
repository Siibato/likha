import 'dart:convert';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../assessment_local_datasource_base.dart';

mixin SubmissionDataSourceMixin on AssessmentLocalDataSourceBase {
  @override
  Future<void> saveAnswersLocally({
    required String submissionId,
    required String answersJson,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      final answers = jsonDecode(answersJson) as List<dynamic>;

      await db.transaction((txn) async {
        // Delete existing answers for this submission
        await txn.delete('submission_answers', where: 'submission_id = ?', whereArgs: [submissionId]);

        // Insert normalized answers
        for (final answerData in answers) {
          final answer = answerData as Map<String, dynamic>;
          final answerId = answer['id'] as String? ?? const Uuid().v4();
          await txn.insert(
            'submission_answers',
            {
              'id': answerId,
              'submission_id': submissionId,
              'question_id': answer['question_id'] as String,
              'points': 0,
              'cached_at': now.toIso8601String(),
              'needs_sync': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Insert answer items if present
          if (answer['selected_choices'] != null) {
            final choices = answer['selected_choices'] as List<dynamic>;
            for (final choiceId in choices) {
              await txn.insert(
                'submission_answer_items',
                {
                  'id': const Uuid().v4(),
                  'submission_answer_id': answerId,
                  'choice_id': choiceId as String,
                  'answer_text': null,
                  'is_correct': 0,
                  'cached_at': now.toIso8601String(),
                  'needs_sync': 1,
                },
              );
            }
          } else if (answer['answer_text'] != null) {
            await txn.insert(
              'submission_answer_items',
              {
                'id': const Uuid().v4(),
                'submission_answer_id': answerId,
                'choice_id': null,
                'answer_text': answer['answer_text'] as String,
                'is_correct': 0,
                'cached_at': now.toIso8601String(),
                'needs_sync': 1,
              },
            );
          }
        }

        // Mark submission as needing sync
        await txn.update(
          'assessment_submissions',
          {
            'needs_sync': 1,
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.saveAnswers,
          payload: {'submission_id': submissionId, 'answers': answers},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to save answers locally: $e');
    }
  }

  @override
  Future<void> cacheStartSubmissionResult({
    required String submissionId,
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
    required DateTime startedAt,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.insert(
        'assessment_submissions',
        {
          'id': submissionId,
          'assessment_id': assessmentId,
          'user_id': studentId,
          'started_at': startedAt.toIso8601String(),
          'total_points': 0,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'cached_at': now.toIso8601String(),
          'needs_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache start submission result: $e');
    }
  }

  @override
  Future<String> startAssessmentLocally({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  }) async {
    try {
      final db = await localDatabase.database;
      final localId = const Uuid().v4();
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.insert('assessment_submissions', {
          'id': localId,
          'assessment_id': assessmentId,
          'user_id': studentId,
          'started_at': now.toIso8601String(),
          'total_points': 0,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'cached_at': now.toIso8601String(),
          'needs_sync': 1,
        });
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.create,
          payload: {'id': localId, 'assessment_id': assessmentId, 'user_id': studentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
      return localId;
    } catch (e) {
      throw CacheException('Failed to start assessment locally: $e');
    }
  }

  @override
  Future<StartSubmissionResultModel?> getCachedStartResult(String submissionId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query('assessment_submissions', where: 'id = ? AND deleted_at IS NULL', whereArgs: [submissionId]);
      if (results.isEmpty) return null;
      final submission = results.first;
      return StartSubmissionResultModel(
        submissionId: submission['id'] as String,
        startedAt: DateTime.parse(submission['started_at'] as String),
        questions: [],
      );
    } catch (e) {
      throw CacheException('Failed to get cached start result: $e');
    }
  }

  @override
  Future<SubmissionSummaryModel?> getCachedStudentSubmission(
    String assessmentId,
    String studentId,
  ) async {
    try {
      final db = await localDatabase.database;
      final results = await db.rawQuery('''
        SELECT s.*, u.full_name as student_name, u.username as student_username
        FROM assessment_submissions s
        LEFT JOIN users u ON u.id = s.user_id
        WHERE s.assessment_id = ? AND s.user_id = ? AND s.deleted_at IS NULL
        ORDER BY s.started_at DESC LIMIT 1
      ''', [assessmentId, studentId]);

      if (results.isEmpty) {
        return null;
      }

      final rawRow = results.first;
      return SubmissionSummaryModel(
        id: rawRow['id'] as String,
        assessmentId: rawRow['assessment_id'] as String? ?? '',
        studentId: rawRow['user_id'] as String? ?? '',
        studentName: rawRow['student_name'] as String? ?? '',
        studentUsername: rawRow['student_username'] as String? ?? '',
        startedAt: DateTime.parse(rawRow['started_at'] as String),
        submittedAt: rawRow['submitted_at'] != null ? DateTime.parse(rawRow['submitted_at'] as String) : null,
        autoScore: (rawRow['earned_points'] as num?)?.toDouble() ?? 0.0,
        finalScore: (rawRow['earned_points'] as num?)?.toDouble() ?? 0.0,
        totalPoints: rawRow['total_points'] as int? ?? 0,
        isSubmitted: rawRow['submitted_at'] != null,
      );
    } catch (e) {
      throw CacheException('Failed to get student submission: $e');
    }
  }

  @override
  Future<void> submitAssessmentLocally({
    required String submissionId,
    required String assessmentId,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.update(
          'assessment_submissions',
          {
            'submitted_at': now.toIso8601String(),
            'needs_sync': 1,
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.submit,
          payload: {'submission_id': submissionId, 'assessment_id': assessmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to submit assessment locally: $e');
    }
  }

  @override
  Future<SubmissionDetailModel?> getCachedSubmissionDetail(String submissionId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.rawQuery('''
        SELECT s.*, u.full_name as student_name
        FROM assessment_submissions s
        LEFT JOIN users u ON u.id = s.user_id
        WHERE s.id = ? AND s.deleted_at IS NULL
      ''', [submissionId]);
      if (results.isEmpty) return null;
      final sub = results.first;

      List<SubmissionAnswerModel> answers = [];
      // For now, return empty answers (they're stored in submission_answers table)
      // A full implementation would reconstruct from submission_answers and submission_answer_items

      return SubmissionDetailModel(
        id: sub['id'] as String,
        assessmentId: sub['assessment_id'] as String? ?? '',
        studentId: sub['user_id'] as String? ?? '',
        studentName: sub['student_name'] as String? ?? '',
        startedAt: DateTime.parse(sub['started_at'] as String),
        submittedAt: sub['submitted_at'] != null ? DateTime.parse(sub['submitted_at'] as String) : null,
        autoScore: (sub['earned_points'] as num?)?.toDouble() ?? 0.0,
        finalScore: (sub['earned_points'] as num?)?.toDouble() ?? 0.0,
        isSubmitted: sub['submitted_at'] != null,
        totalPoints: sub['total_points'] as int? ?? 0,
        answers: answers,
      );
    } catch (e) {
      throw CacheException('Failed to get cached submission detail: $e');
    }
  }

  @override
  Future<void> cacheSubmissionDetail(SubmissionDetailModel submission) async {
    try {
      final db = await localDatabase.database;
      await db.insert(
        'assessment_submissions',
        {
          'id': submission.id,
          'assessment_id': submission.assessmentId,
          'user_id': submission.studentId,
          'started_at': submission.startedAt.toIso8601String(),
          'submitted_at': submission.submittedAt?.toIso8601String(),
          'total_points': submission.totalPoints,
          'earned_points': submission.autoScore,
          'created_at': submission.startedAt.toIso8601String(),
          'updated_at': submission.submittedAt?.toIso8601String() ?? submission.startedAt.toIso8601String(),
          'cached_at': DateTime.now().toIso8601String(),
          'needs_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache submission detail: $e');
    }
  }

  @override
  Future<List<SubmissionSummaryModel>> getCachedSubmissions(String assessmentId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.rawQuery('''
        SELECT s.*, u.full_name as student_name, u.username as student_username
        FROM assessment_submissions s
        LEFT JOIN users u ON u.id = s.user_id
        WHERE s.assessment_id = ? AND s.deleted_at IS NULL
        ORDER BY s.started_at DESC
      ''', [assessmentId]);

      if (results.isEmpty) return [];

      return results.map((row) => SubmissionSummaryModel(
        id: row['id'] as String,
        assessmentId: row['assessment_id'] as String? ?? '',
        studentId: row['user_id'] as String? ?? '',
        studentName: row['student_name'] as String? ?? '',
        studentUsername: row['student_username'] as String? ?? '',
        startedAt: DateTime.parse(row['started_at'] as String),
        submittedAt: row['submitted_at'] != null ? DateTime.parse(row['submitted_at'] as String) : null,
        autoScore: (row['earned_points'] as num?)?.toDouble() ?? 0.0,
        finalScore: (row['earned_points'] as num?)?.toDouble() ?? 0.0,
        totalPoints: row['total_points'] as int? ?? 0,
        isSubmitted: row['submitted_at'] != null,
      )).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<int> getCachedSubmissionCount(String assessmentId) async {
    try {
      final db = await localDatabase.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM assessment_submissions WHERE assessment_id = ? AND deleted_at IS NULL',
        [assessmentId],
      );
      final count = (result.first['count'] as int?) ?? 0;
      return count;
    } catch (e) {
      throw CacheException('Failed to get submission count: $e');
    }
  }

  @override
  Future<bool?> hasStudentSubmittedAssessment(String assessmentId, String studentId) async {
    try {
      final db = await localDatabase.database;
      final result = await db.query(
        'assessment_submissions',
        columns: ['submitted_at'],
        where: 'assessment_id = ? AND user_id = ? AND deleted_at IS NULL',
        whereArgs: [assessmentId, studentId],
      );
      if (result.isEmpty) {
        return null; // No submission found
      }
      final isSubmitted = result.first['submitted_at'] != null;
      return isSubmitted; // false = in-progress, true = submitted
    } catch (e) {
      throw CacheException('Failed to check submission status: $e');
    }
  }

  @override
  Future<void> cacheSubmissions(String assessmentId, List<SubmissionSummaryModel> submissions) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        for (final submission in submissions) {
          await txn.insert(
            'assessment_submissions',
            {
              'id': submission.id,
              'assessment_id': assessmentId,
              'user_id': submission.studentId,
              'started_at': submission.startedAt.toIso8601String(),
              'submitted_at': submission.submittedAt?.toIso8601String(),
              'total_points': submission.totalPoints,
              'earned_points': submission.autoScore,
              'created_at': submission.startedAt.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'cached_at': DateTime.now().toIso8601String(),
              'needs_sync': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache submissions: $e');
    }
  }

  @override
  Future<void> overrideAnswerLocally({
    required String answerId,
    required bool isCorrect,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Find the answer in submission_answers
        final answerResults = await txn.query(
          'submission_answers',
          where: 'id = ?',
          whereArgs: [answerId],
        );

        if (answerResults.isNotEmpty) {
          final submissionId = answerResults.first['submission_id'] as String;

          // Update answer items to reflect override
          await txn.update(
            'submission_answer_items',
            {
              'is_correct': isCorrect ? 1 : 0,
            },
            where: 'submission_answer_id = ?',
            whereArgs: [answerId],
          );

          // Mark submission as needing sync
          await txn.update(
            'assessment_submissions',
            {
              'needs_sync': 1,
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [submissionId],
          );
        }

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.overrideAnswer,
          payload: {'answer_id': answerId, 'is_correct': isCorrect},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to override answer locally: $e');
    }
  }
}
