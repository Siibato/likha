import 'dart:convert';

import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

abstract class AssessmentLocalDataSource {
  Future<List<AssessmentModel>> getCachedAssessments(String classId);
  Future<(AssessmentModel, List<QuestionModel>)> getCachedAssessmentDetail(String assessmentId);
  Future<void> cacheAssessments(List<AssessmentModel> assessments);
  Future<void> cacheAssessmentDetail(AssessmentModel assessment, List<QuestionModel> questions);
  Future<void> cacheQuestions(List<QuestionModel> questions);
  Future<void> updateQuestionLocally({
    required String questionId,
    required Map<String, dynamic> updates,
  });
  Future<void> deleteQuestionLocally({required String questionId});
  Future<void> updateQuestionId({
    required String localId,
    required String serverId,
  });
  Future<void> updateChoiceIds({
    required String questionId,
    required Map<String, String> idMapping,
  });
  Future<void> updateCorrectAnswerIds({
    required String questionId,
    required Map<String, String> idMapping,
  });
  Future<void> saveAnswersLocally({
    required String submissionId,
    required String answersJson,
  });
  Future<void> cacheStartSubmissionResult({
    required String submissionId,
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
    required DateTime startedAt,
  });
  Future<String> startAssessmentLocally({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  });
  Future<StartSubmissionResultModel?> getCachedStartResult(String submissionId);
  Future<void> submitAssessmentLocally({
    required String submissionId,
    required String assessmentId,
  });
  Future<SubmissionDetailModel?> getCachedSubmissionDetail(String submissionId);
  Future<void> cacheSubmissionDetail(SubmissionDetailModel submission);
  Future<String> createAssessmentLocally({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
  });
  Future<List<SubmissionSummaryModel>> getCachedSubmissions(String assessmentId);
  Future<void> cacheSubmissions(String assessmentId, List<SubmissionSummaryModel> submissions);
  Future<AssessmentStatisticsModel?> getCachedStatistics(String assessmentId);
  Future<void> cacheStatistics(AssessmentStatisticsModel statistics);
  Future<StudentResultModel?> getCachedStudentResults(String submissionId);
  Future<void> cacheStudentResults(StudentResultModel result);
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
          map['is_offline_mutation'] = 0;

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
        assessmentMap['is_offline_mutation'] = 0;

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
              'is_offline_mutation': 0,
              'sync_status': 'synced',
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
            'is_offline_mutation': 1,
            'sync_status': 'pending',
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [submissionId],
        );

        // Enqueue sync - save answers operations should always be queued
        // FIX: Use SyncOperation.saveAnswers and decode answers to array
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assessmentSubmission,
            operation: SyncOperation.saveAnswers,
            payload: {
              'submission_id': submissionId,
              'answers': jsonDecode(answersJson) as List<dynamic>,
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
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
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
      final db = await _localDatabase.database;
      final localId = const Uuid().v4();
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Insert into assessment_submissions
        await txn.insert(
          'assessment_submissions',
          {
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
            'is_offline_mutation': 1,
          },
        );

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assessmentSubmission,
            operation: SyncOperation.create,
            payload: {
              'local_id': localId,
              'assessment_id': assessmentId,
              'student_id': studentId,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });

      return localId;
    } catch (e) {
      throw CacheException('Failed to start assessment locally: $e');
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
            'is_offline_mutation': 1,
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

      // Parse answers from answers_json if available
      List<SubmissionAnswerModel> answers = [];
      final answersJson = sub['answers_json'] as String?;
      if (answersJson != null && answersJson.isNotEmpty) {
        try {
          final answersList = jsonDecode(answersJson) as List<dynamic>;
          answers = answersList.map((a) => SubmissionAnswerModel.fromJson(a as Map<String, dynamic>)).toList();
        } catch (e) {
          // Ignore parse errors, return empty answers
        }
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
          'is_offline_mutation': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache submission detail: $e');
    }
  }

  /// Update a question locally with the provided fields
  /// Automatically sets updated_at timestamp and marks as dirty for sync
  Future<void> updateQuestionLocally({
    required String questionId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final db = await _localDatabase.database;
      final now = DateTime.now();

      // Add timestamp and sync markers to updates
      updates['updated_at'] = now.toIso8601String();
      updates['is_offline_mutation'] = 1;
      updates['sync_status'] = 'pending';

      await db.update(
        'questions',
        updates,
        where: 'id = ?',
        whereArgs: [questionId],
      );
    } catch (e) {
      throw CacheException('Failed to update question locally: $e');
    }
  }

  /// Soft delete a question locally by setting deleted_at timestamp
  /// Marks as dirty for sync and preserves data for recovery and audit
  Future<void> deleteQuestionLocally({required String questionId}) async {
    try {
      final db = await _localDatabase.database;
      await db.update(
        'questions',
        {
          'deleted_at': DateTime.now().toIso8601String(),
          'is_offline_mutation': 1,
          'sync_status': 'pending',
        },
        where: 'id = ?',
        whereArgs: [questionId],
      );
    } catch (e) {
      throw CacheException('Failed to delete question locally: $e');
    }
  }

  /// Update question ID from local UUID to server UUID after successful sync
  @override
  Future<void> updateQuestionId({
    required String localId,
    required String serverId,
  }) async {
    try {
      final db = await _localDatabase.database;
      await db.update(
        'questions',
        {'id': serverId},
        where: 'id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheException('Failed to update question ID: $e');
    }
  }

  /// Update choice IDs in question's choices_json after sync
  /// Maps local choice UUIDs to server-assigned UUIDs
  @override
  Future<void> updateChoiceIds({
    required String questionId,
    required Map<String, String> idMapping,
  }) async {
    try {
      final db = await _localDatabase.database;

      // Get current choices_json
      final result = await db.query(
        'questions',
        columns: ['choices_json'],
        where: 'id = ?',
        whereArgs: [questionId],
      );

      if (result.isEmpty) return;

      final choicesJson = result.first['choices_json'] as String?;
      if (choicesJson == null || choicesJson.isEmpty) return;

      // Parse, update, and save choice IDs
      final choices = jsonDecode(choicesJson) as List<dynamic>;
      for (final choice in choices) {
        final oldId = choice['id'] as String?;
        if (oldId != null && idMapping.containsKey(oldId)) {
          choice['id'] = idMapping[oldId];
        }
      }

      await db.update(
        'questions',
        {
          'choices_json': jsonEncode(choices),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [questionId],
      );
    } catch (e) {
      throw CacheException('Failed to update choice IDs: $e');
    }
  }

  /// Update correct answer IDs in question's correct_answers_json after sync
  /// Maps local answer UUIDs to server-assigned UUIDs
  @override
  Future<void> updateCorrectAnswerIds({
    required String questionId,
    required Map<String, String> idMapping,
  }) async {
    try {
      final db = await _localDatabase.database;

      // Get current correct_answers_json
      final result = await db.query(
        'questions',
        columns: ['correct_answers_json'],
        where: 'id = ?',
        whereArgs: [questionId],
      );

      if (result.isEmpty) return;

      final answersJson = result.first['correct_answers_json'] as String?;
      if (answersJson == null || answersJson.isEmpty) return;

      // Parse, update, and save answer IDs
      final answers = jsonDecode(answersJson) as List<dynamic>;
      for (final answer in answers) {
        final oldId = answer['id'] as String?;
        if (oldId != null && idMapping.containsKey(oldId)) {
          answer['id'] = idMapping[oldId];
        }
      }

      await db.update(
        'questions',
        {
          'correct_answers_json': jsonEncode(answers),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [questionId],
      );
    } catch (e) {
      throw CacheException('Failed to update correct answer IDs: $e');
    }
  }

  @override
  Future<List<SubmissionSummaryModel>> getCachedSubmissions(String assessmentId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'assessment_submissions',
        where: 'assessment_id = ?',
        whereArgs: [assessmentId],
        orderBy: 'started_at DESC',
      );

      if (results.isEmpty) {
        throw CacheException('No cached submissions for assessment $assessmentId');
      }

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
  Future<void> cacheSubmissions(String assessmentId, List<SubmissionSummaryModel> submissions) async {
    try {
      final db = await _localDatabase.database;
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
  Future<AssessmentStatisticsModel?> getCachedStatistics(String assessmentId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'assessment_statistics_cache',
        where: 'assessment_id = ?',
        whereArgs: [assessmentId],
      );

      if (results.isEmpty) return null;

      final row = results.first;
      final statisticsJson = jsonDecode(row['statistics_json'] as String) as Map<String, dynamic>;
      return AssessmentStatisticsModel.fromJson(statisticsJson);
    } catch (e) {
      throw CacheException('Failed to get cached statistics: $e');
    }
  }

  @override
  Future<void> cacheStatistics(AssessmentStatisticsModel statistics) async {
    try {
      final db = await _localDatabase.database;

      // Convert stats to JSON manually (avoiding need for toJson method)
      final statsJson = {
        'assessment_id': statistics.assessmentId,
        'title': statistics.title,
        'total_points': statistics.totalPoints,
        'submission_count': statistics.submissionCount,
        'class_statistics': {
          'mean': statistics.classStatistics.mean,
          'median': statistics.classStatistics.median,
          'highest': statistics.classStatistics.highest,
          'lowest': statistics.classStatistics.lowest,
          'score_distribution': statistics.classStatistics.scoreDistribution.map((bucket) => {
            'range': bucket.range,
            'count': bucket.count,
          }).toList(),
        },
        'question_statistics': statistics.questionStatistics.map((qs) => {
          'question_id': qs.questionId,
          'question_text': qs.questionText,
          'question_type': qs.questionType,
          'points': qs.points,
          'correct_count': qs.correctCount,
          'incorrect_count': qs.incorrectCount,
          'correct_percentage': qs.correctPercentage,
        }).toList(),
      };

      await db.insert(
        'assessment_statistics_cache',
        {
          'assessment_id': statistics.assessmentId,
          'statistics_json': jsonEncode(statsJson),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache statistics: $e');
    }
  }

  @override
  Future<StudentResultModel?> getCachedStudentResults(String submissionId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'student_results_cache',
        where: 'submission_id = ?',
        whereArgs: [submissionId],
      );

      if (results.isEmpty) return null;

      final row = results.first;
      final resultsJson = jsonDecode(row['results_json'] as String) as Map<String, dynamic>;
      return StudentResultModel.fromJson(resultsJson);
    } catch (e) {
      throw CacheException('Failed to get cached student results: $e');
    }
  }

  @override
  Future<void> cacheStudentResults(StudentResultModel result) async {
    try {
      final db = await _localDatabase.database;

      // Convert results to JSON manually
      final resultsJson = {
        'submission_id': result.submissionId,
        'auto_score': result.autoScore,
        'final_score': result.finalScore,
        'total_points': result.totalPoints,
        'submitted_at': result.submittedAt?.toIso8601String(),
        'answers': result.answers.map((ans) => {
          'question_id': ans.questionId,
          'question_text': ans.questionText,
          'question_type': ans.questionType,
          'points': ans.points,
          'points_awarded': ans.pointsAwarded,
          'is_correct': ans.isCorrect,
          'answer_text': ans.answerText,
          'selected_choices': ans.selectedChoices,
          'enumeration_answers': ans.enumerationAnswers?.map((ea) => {
            'answer_text': ea.answerText,
            'is_correct': ea.isCorrect,
          }).toList(),
          'correct_answers': ans.correctAnswers,
        }).toList(),
      };

      await db.insert(
        'student_results_cache',
        {
          'submission_id': result.submissionId,
          'results_json': jsonEncode(resultsJson),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache student results: $e');
    }
  }

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
      final db = await _localDatabase.database;
      final assessmentId = const Uuid().v4();
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Insert assessment with local UUID
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
            'show_results_immediately': showResultsImmediately ?? false ? 1 : 0,
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
            'is_offline_mutation': 1,
          },
        );

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assessment,
            operation: SyncOperation.create,
            payload: {
              'local_id': assessmentId,
              'class_id': classId,
              'title': title,
              if (description != null) 'description': description,
              'time_limit_minutes': timeLimitMinutes,
              'open_at': openAt,
              'close_at': closeAt,
              if (showResultsImmediately != null)
                'show_results_immediately': showResultsImmediately,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });

      return assessmentId;
    } catch (e) {
      throw CacheException('Failed to create assessment locally: $e');
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
