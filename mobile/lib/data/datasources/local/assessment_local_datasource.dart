import 'dart:convert';

import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

abstract class AssessmentLocalDataSource {
  Future<List<AssessmentModel>> getCachedAssessments(String classId);
  Future<(AssessmentModel, List<QuestionModel>)> getCachedAssessmentDetail(String assessmentId);
  Future<void> cacheAssessments(List<AssessmentModel> assessments);
  Future<void> cacheAssessmentDetail(AssessmentModel assessment, List<QuestionModel> questions);
  Future<void> cacheQuestions(List<QuestionModel> questions);
  Future<void> saveAnswersLocally({
    required String submissionId,
    required String answersJson,
  });
  Future<void> cacheStartSubmissionResult({
    required String submissionId,
    required DateTime startedAt,
  });
  Future<StartSubmissionResultModel?> getCachedStartResult(String submissionId);
  Future<void> submitAssessmentLocally({
    required String submissionId,
    required String assessmentId,
  });
  Future<SubmissionDetailModel?> getCachedSubmissionDetail(String submissionId);
  Future<void> cacheSubmissionDetail(SubmissionDetailModel submission);
  Future<void> clearAllCache();
}

class AssessmentLocalDataSourceImpl implements AssessmentLocalDataSource {
  final LocalDatabase _localDatabase;
  final SyncQueue _syncQueue;

  AssessmentLocalDataSourceImpl(this._localDatabase, this._syncQueue);

  @override
  Future<List<AssessmentModel>> getCachedAssessments(String classId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'assessments',
        where: 'class_id = ?',
        whereArgs: [classId],
        orderBy: 'created_at DESC',
      );

      if (results.isEmpty) {
        throw CacheException('No cached assessments for class $classId');
      }

      return results.map(AssessmentModel.fromMap).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<(AssessmentModel, List<QuestionModel>)> getCachedAssessmentDetail(String assessmentId) async {
    try {
      final db = await _localDatabase.database;
      final assessmentResults = await db.query(
        'assessments',
        where: 'id = ?',
        whereArgs: [assessmentId],
      );

      if (assessmentResults.isEmpty) {
        throw CacheException('Assessment $assessmentId not cached');
      }

      final assessment = AssessmentModel.fromMap(assessmentResults.first);

      final questionResults = await db.query(
        'questions',
        where: 'assessment_id = ?',
        whereArgs: [assessmentId],
        orderBy: 'order_index ASC',
      );

      final questions = questionResults.map((q) {
        // Reconstruct from JSON since QuestionModel has complex nested structures
        return QuestionModel.fromJson(jsonDecode(jsonEncode(q)));
      }).toList();

      return (assessment, questions);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheAssessments(List<AssessmentModel> assessments) async {
    try {
      final db = await _localDatabase.database;
      await db.transaction((txn) async {
        for (final assessment in assessments) {
          final map = assessment.toMap();
          map['cached_at'] = DateTime.now().toIso8601String();
          map['sync_status'] = 'synced';
          map['is_dirty'] = 0;

          await txn.insert(
            'assessments',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache assessments: $e');
    }
  }

  @override
  Future<void> cacheAssessmentDetail(AssessmentModel assessment, List<QuestionModel> questions) async {
    try {
      final db = await _localDatabase.database;
      await db.transaction((txn) async {
        // Cache assessment
        final assessmentMap = assessment.toMap();
        assessmentMap['cached_at'] = DateTime.now().toIso8601String();
        assessmentMap['sync_status'] = 'synced';
        assessmentMap['is_dirty'] = 0;

        await txn.insert('assessments', assessmentMap, conflictAlgorithm: ConflictAlgorithm.replace);

        // Cache questions
        for (final question in questions) {
          // Store questions_json as JSON for later reconstruction
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
              'choices_json': question.choices != null ? jsonEncode(question.choices?.map((c) => {'id': c.id, 'choice_text': c.choiceText, 'is_correct': c.isCorrect, 'order_index': c.orderIndex}).toList()) : null,
              'correct_answers_json': question.correctAnswers != null ? jsonEncode(question.correctAnswers?.map((a) => {'id': a.id, 'answer_text': a.answerText}).toList()) : null,
              'enumeration_items_json': question.enumerationItems != null ? jsonEncode(question.enumerationItems) : null,
              'cached_at': DateTime.now().toIso8601String(),
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
  Future<void> cacheQuestions(List<QuestionModel> questions) async {
    try {
      final db = await _localDatabase.database;
      await db.transaction((txn) async {
        for (final question in questions) {
          await txn.insert(
            'questions',
            {
              'id': question.id,
              'assessment_id': '', // Will be updated elsewhere
              'question_type': question.questionType,
              'question_text': question.questionText,
              'points': question.points,
              'order_index': question.orderIndex,
              'is_multi_select': question.isMultiSelect ? 1 : 0,
              'cached_at': DateTime.now().toIso8601String(),
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
  Future<void> saveAnswersLocally({
    required String submissionId,
    required String answersJson,
  }) async {
    try {
      final db = await _localDatabase.database;
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Update submission answers
        await txn.update(
          'assessment_submissions',
          {
            'answers_json': answersJson,
            'is_dirty': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );

        // Enqueue sync - save answers operations should always be queued
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assessmentSubmission,
            operation: SyncOperation.update,
            payload: {
              'submission_id': submissionId,
              'answers_json': answersJson,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });
    } catch (e) {
      throw CacheException('Failed to save answers locally: $e');
    }
  }

  @override
  Future<void> cacheStartSubmissionResult({
    required String submissionId,
    required DateTime startedAt,
  }) async {
    try {
      final db = await _localDatabase.database;
      final now = DateTime.now();

      // Create or update submission
      await db.insert(
        'assessment_submissions',
        {
          'id': submissionId,
          'assessment_id': '', // Will be filled elsewhere
          'student_id': '', // Will be filled elsewhere
          'student_name': '', // Will be filled elsewhere
          'student_username': '', // Will be filled elsewhere
          'started_at': startedAt.toIso8601String(),
          'local_start_at': startedAt.toIso8601String(),
          'is_submitted': 0,
          'cached_at': now.toIso8601String(),
          'sync_status': 'synced',
          'is_dirty': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache start submission result: $e');
    }
  }

  @override
  Future<StartSubmissionResultModel?> getCachedStartResult(String submissionId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'assessment_submissions',
        where: 'id = ?',
        whereArgs: [submissionId],
      );

      if (results.isEmpty) return null;

      final submission = results.first;
      return StartSubmissionResultModel(
        submissionId: submission['id'] as String,
        startedAt: DateTime.parse(submission['started_at'] as String),
        questions: [], // Questions would be fetched separately
      );
    } catch (e) {
      throw CacheException('Failed to get cached start result: $e');
    }
  }

  @override
  Future<void> submitAssessmentLocally({
    required String submissionId,
    required String assessmentId,
  }) async {
    try {
      final db = await _localDatabase.database;
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Mark submission as submitted locally
        await txn.update(
          'assessment_submissions',
          {
            'is_submitted': 1,
            'submitted_at': now.toIso8601String(),
            'is_dirty': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assessmentSubmission,
            operation: SyncOperation.submit,
            payload: {
              'submission_id': submissionId,
              'assessment_id': assessmentId,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });
    } catch (e) {
      throw CacheException('Failed to submit assessment locally: $e');
    }
  }

  @override
  Future<SubmissionDetailModel?> getCachedSubmissionDetail(String submissionId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'assessment_submissions',
        where: 'id = ?',
        whereArgs: [submissionId],
      );

      if (results.isEmpty) return null;

      final sub = results.first;
      return SubmissionDetailModel(
        id: sub['id'] as String,
        assessmentId: sub['assessment_id'] as String? ?? '',
        studentId: sub['student_id'] as String? ?? '',
        studentName: sub['student_name'] as String? ?? '',
        startedAt: DateTime.parse(sub['started_at'] as String),
        submittedAt: sub['submitted_at'] != null ? DateTime.parse(sub['submitted_at'] as String) : null,
        autoScore: 0.0,
        finalScore: 0.0,
        isSubmitted: (sub['is_submitted'] as int?) == 1,
        answers: [],
      );
    } catch (e) {
      throw CacheException('Failed to get cached submission detail: $e');
    }
  }

  @override
  Future<void> cacheSubmissionDetail(SubmissionDetailModel submission) async {
    try {
      final db = await _localDatabase.database;
      await db.insert(
        'assessment_submissions',
        {
          'id': submission.id,
          'assessment_id': submission.assessmentId,
          'student_id': submission.studentId,
          'student_name': submission.studentName,
          'student_username': '', // Not available
          'started_at': submission.startedAt.toIso8601String(),
          'submitted_at': submission.submittedAt?.toIso8601String(),
          'auto_score': submission.autoScore.toInt(),
          'final_score': submission.finalScore.toInt(),
          'is_submitted': submission.isSubmitted ? 1 : 0,
          'answers_json': jsonEncode(submission.answers.map((a) => a).toList()),
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_dirty': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache submission detail: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      final db = await _localDatabase.database;
      await db.delete('assessments');
      await db.delete('questions');
      await db.delete('assessment_submissions');
    } catch (e) {
      throw CacheException('Failed to clear assessment cache: $e');
    }
  }
}
