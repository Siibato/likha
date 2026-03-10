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
      await db.transaction((txn) async {
        await txn.update(
          'assessment_submissions',
          {
            'answers_json': answersJson,
            'is_offline_mutation': 1,
            'sync_status': 'pending',
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
          payload: {'submission_id': submissionId, 'answers': jsonDecode(answersJson) as List<dynamic>},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
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
          'student_id': studentId,
          'student_name': studentName,
          'student_username': studentUsername,
          'started_at': startedAt.toIso8601String(),
          'local_start_at': startedAt.toIso8601String(),
          'is_submitted': 0,
          'updated_at': now.toIso8601String(),
          'cached_at': now.toIso8601String(),
          'sync_status': 'synced',
          'is_offline_mutation': 0,
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
          'local_id': localId,
          'assessment_id': assessmentId,
          'student_id': studentId,
          'student_name': studentName,
          'student_username': studentUsername,
          'started_at': now.toIso8601String(),
          'is_submitted': 0,
          'updated_at': now.toIso8601String(),
          'cached_at': now.toIso8601String(),
          'sync_status': 'pending',
          'is_offline_mutation': 1,
        });
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.create,
          payload: {'local_id': localId, 'assessment_id': assessmentId, 'student_id': studentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
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
      final results = await db.query('assessment_submissions', where: 'id = ?', whereArgs: [submissionId]);
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
      print('🔎 [DataSource] getCachedStudentSubmission() START - assessmentId: $assessmentId, studentId: $studentId');
      final results = await db.query(
        'assessment_submissions',
        where: 'assessment_id = ? AND student_id = ? AND deleted_at IS NULL',
        whereArgs: [assessmentId, studentId],
        orderBy: 'started_at DESC',
        limit: 1,
      );
      print('🔎 [DataSource] getCachedStudentSubmission() - database query returned ${results.length} submission(s)');

      if (results.isEmpty) {
        print('🔎 [DataSource] getCachedStudentSubmission() - NO SUBMISSIONS FOUND in DB');
        return null;
      }

      final rawRow = results.first;
      print('🔎 [DataSource] getCachedStudentSubmission() - raw DB row: id=${rawRow['id']}, is_submitted=${rawRow['is_submitted']}, submitted_at=${rawRow['submitted_at']}, started_at=${rawRow['started_at']}');

      final submission = SubmissionSummaryModel.fromMap(rawRow);
      print('🔎 [DataSource] getCachedStudentSubmission() RESULT - id: ${submission.id}, isSubmitted: ${submission.isSubmitted}, submittedAt: ${submission.submittedAt}, startedAt: ${submission.startedAt}');
      return submission;
    } catch (e, st) {
      print('❌ [DataSource] getCachedStudentSubmission() EXCEPTION: $e');
      print('❌ [DataSource] getCachedStudentSubmission() STACK: $st');
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
            'is_submitted': 1,
            'submitted_at': now.toIso8601String(),
            'is_offline_mutation': 1,
            'sync_status': 'pending',
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
          maxRetries: 5,
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
      final results = await db.query('assessment_submissions', where: 'id = ?', whereArgs: [submissionId]);
      if (results.isEmpty) return null;
      final sub = results.first;

      List<SubmissionAnswerModel> answers = [];
      final answersJson = sub['answers_json'] as String?;
      if (answersJson != null && answersJson.isNotEmpty) {
        try {
          final answersList = jsonDecode(answersJson) as List<dynamic>;
          answers = answersList.map((a) => SubmissionAnswerModel.fromJson(a as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      return SubmissionDetailModel(
        id: sub['id'] as String,
        assessmentId: sub['assessment_id'] as String? ?? '',
        studentId: sub['student_id'] as String? ?? '',
        studentName: sub['student_name'] as String? ?? '',
        startedAt: DateTime.parse(sub['started_at'] as String),
        submittedAt: sub['submitted_at'] != null ? DateTime.parse(sub['submitted_at'] as String) : null,
        autoScore: (sub['auto_score'] as int?)?.toDouble() ?? 0.0,
        finalScore: (sub['final_score'] as int?)?.toDouble() ?? 0.0,
        isSubmitted: (sub['is_submitted'] as int?) == 1,
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
          'student_id': submission.studentId,
          'student_name': submission.studentName,
          'student_username': '',
          'started_at': submission.startedAt.toIso8601String(),
          'submitted_at': submission.submittedAt?.toIso8601String(),
          'auto_score': submission.autoScore.toInt(),
          'final_score': submission.finalScore.toInt(),
          'is_submitted': submission.isSubmitted ? 1 : 0,
          'answers_json': jsonEncode(submission.answers),
          'updated_at': submission.submittedAt?.toIso8601String() ?? submission.startedAt.toIso8601String(),
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_offline_mutation': 0,
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
      final results = await db.query(
        'assessment_submissions',
        where: 'assessment_id = ?',
        whereArgs: [assessmentId],
        orderBy: 'started_at DESC',
      );
      if (results.isEmpty) throw CacheException('No cached submissions for assessment $assessmentId');
      return results.map((row) => SubmissionSummaryModel(
        id: row['id'] as String,
        studentId: row['student_id'] as String? ?? '',
        studentName: row['student_name'] as String? ?? '',
        studentUsername: row['student_username'] as String? ?? '',
        startedAt: DateTime.parse(row['started_at'] as String),
        submittedAt: row['submitted_at'] != null ? DateTime.parse(row['submitted_at'] as String) : null,
        autoScore: (row['auto_score'] as int?)?.toDouble() ?? 0.0,
        finalScore: (row['final_score'] as int?)?.toDouble() ?? 0.0,
        isSubmitted: (row['is_submitted'] as int?) == 1,
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
      print('📊 [DataSource] getCachedSubmissionCount() - assessmentId: $assessmentId, count: $count');
      return count;
    } catch (e) {
      print('❌ [DataSource] getCachedSubmissionCount() ERROR: $e');
      throw CacheException('Failed to get submission count: $e');
    }
  }

  @override
  Future<bool> hasStudentSubmittedAssessment(String assessmentId, String studentId) async {
    try {
      final db = await localDatabase.database;
      final result = await db.query(
        'assessment_submissions',
        columns: ['is_submitted'],
        where: 'assessment_id = ? AND student_id = ? AND deleted_at IS NULL',
        whereArgs: [assessmentId, studentId],
      );
      if (result.isEmpty) {
        print('📋 [DataSource] hasStudentSubmittedAssessment() - assessmentId: $assessmentId, studentId: $studentId → no submission');
        return false;
      }
      final isSubmitted = (result.first['is_submitted'] as int?) == 1;
      print('📋 [DataSource] hasStudentSubmittedAssessment() - assessmentId: $assessmentId, studentId: $studentId → $isSubmitted');
      return isSubmitted;
    } catch (e) {
      print('❌ [DataSource] hasStudentSubmittedAssessment() ERROR: $e');
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
              'student_id': submission.studentId,
              'student_name': submission.studentName,
              'student_username': submission.studentUsername,
              'started_at': submission.startedAt.toIso8601String(),
              'submitted_at': submission.submittedAt?.toIso8601String(),
              'auto_score': submission.autoScore.toInt(),
              'final_score': submission.finalScore.toInt(),
              'is_submitted': submission.isSubmitted ? 1 : 0,
              'updated_at': DateTime.now().toIso8601String(),
              'cached_at': DateTime.now().toIso8601String(),
              'sync_status': 'synced',
              'is_offline_mutation': 0,
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

      final rows = await db.query(
        'assessment_submissions',
        columns: ['id', 'answers_json'],
        where: "answers_json LIKE ?",
        whereArgs: ['%"$answerId"%'],
      );

      await db.transaction((txn) async {
        if (rows.isNotEmpty) {
          final submissionId = rows.first['id'] as String;
          final rawJson = rows.first['answers_json'] as String?;
          if (rawJson != null) {
            final answers = (jsonDecode(rawJson) as List<dynamic>)
                .cast<Map<String, dynamic>>();
            for (final answer in answers) {
              if (answer['id'] == answerId) {
                answer['is_override_correct'] = isCorrect;
                break;
              }
            }
            await txn.update(
              'assessment_submissions',
              {
                'answers_json': jsonEncode(answers),
                'is_offline_mutation': 1,
                'sync_status': 'pending',
                'updated_at': now.toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [submissionId],
            );
          }
        }
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.overrideAnswer,
          payload: {'answer_id': answerId, 'is_correct': isCorrect},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to override answer locally: $e');
    }
  }
}