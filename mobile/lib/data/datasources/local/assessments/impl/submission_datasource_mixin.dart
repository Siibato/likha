import 'dart:convert';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/core/database/db_schema.dart';
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
        await txn.delete(DbTables.submissionAnswers, where: '${SubmissionAnswersCols.submissionId} = ?', whereArgs: [submissionId]);

        // Insert normalized answers
        for (final answerData in answers) {
          final answer = answerData as Map<String, dynamic>;
          final answerId = answer['id'] as String? ?? const Uuid().v4();
          await txn.insert(
            DbTables.submissionAnswers,
            {
              CommonCols.id: answerId,
              SubmissionAnswersCols.submissionId: submissionId,
              SubmissionAnswersCols.questionId: answer['question_id'] as String,
              SubmissionAnswersCols.points: 0,
              CommonCols.cachedAt: now.toIso8601String(),
              CommonCols.needsSync: 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Insert answer items if present
          if (answer['selected_choices'] != null) {
            final choices = answer['selected_choices'] as List<dynamic>;
            for (final choiceId in choices) {
              await txn.insert(
                DbTables.submissionAnswerItems,
                {
                  CommonCols.id: const Uuid().v4(),
                  SubmissionAnswerItemsCols.submissionAnswerId: answerId,
                  SubmissionAnswerItemsCols.choiceId: choiceId as String,
                  SubmissionAnswerItemsCols.answerText: null,
                  SubmissionAnswerItemsCols.isCorrect: 0,
                  CommonCols.cachedAt: now.toIso8601String(),
                  CommonCols.needsSync: 1,
                },
              );
            }
          } else if (answer['answer_text'] != null) {
            await txn.insert(
              DbTables.submissionAnswerItems,
              {
                CommonCols.id: const Uuid().v4(),
                SubmissionAnswerItemsCols.submissionAnswerId: answerId,
                SubmissionAnswerItemsCols.choiceId: null,
                SubmissionAnswerItemsCols.answerText: answer['answer_text'] as String,
                SubmissionAnswerItemsCols.isCorrect: 0,
                CommonCols.cachedAt: now.toIso8601String(),
                CommonCols.needsSync: 1,
              },
            );
          }
        }

        // Mark submission as needing sync
        await txn.update(
          DbTables.assessmentSubmissions,
          {
            CommonCols.needsSync: 1,
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
          },
          where: '${CommonCols.id} = ?',
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
        DbTables.assessmentSubmissions,
        {
          CommonCols.id: submissionId,
          AssessmentSubmissionsCols.assessmentId: assessmentId,
          AssessmentSubmissionsCols.userId: studentId,
          AssessmentSubmissionsCols.startedAt: startedAt.toIso8601String(),
          AssessmentSubmissionsCols.totalPoints: 0,
          CommonCols.createdAt: now.toIso8601String(),
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.needsSync: 0,
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
        await txn.insert(DbTables.assessmentSubmissions, {
          CommonCols.id: localId,
          AssessmentSubmissionsCols.assessmentId: assessmentId,
          AssessmentSubmissionsCols.userId: studentId,
          AssessmentSubmissionsCols.startedAt: now.toIso8601String(),
          AssessmentSubmissionsCols.totalPoints: 0,
          CommonCols.createdAt: now.toIso8601String(),
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
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
      final results = await db.query(DbTables.assessmentSubmissions, where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL', whereArgs: [submissionId]);
      if (results.isEmpty) return null;
      final submission = results.first;
      return StartSubmissionResultModel(
        submissionId: submission['id'] as String,
        startedAt: DateTime.parse(submission['started_at'] as String),
        questions: const [],
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
        FROM ${DbTables.assessmentSubmissions} s
        LEFT JOIN ${DbTables.users} u ON u.id = s.user_id
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
        studentName: enc.decryptField(rawRow['student_name'] as String?) ?? '',
        studentUsername: enc.decryptField(rawRow['student_username'] as String?) ?? '',
        startedAt: DateTime.parse(rawRow['started_at'] as String),
        submittedAt: rawRow['submitted_at'] != null ? DateTime.parse(rawRow['submitted_at'] as String) : null,
        autoScore: (rawRow['earned_points'] as num?)?.toDouble() ?? 0.0,
        finalScore: (rawRow['earned_points'] as num?)?.toDouble() ?? 0.0,
        totalPoints: (rawRow['total_points'] as num?)?.toDouble() ?? 0.0,
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
          DbTables.assessmentSubmissions,
          {
            AssessmentSubmissionsCols.submittedAt: now.toIso8601String(),
            CommonCols.needsSync: 1,
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
          },
          where: '${CommonCols.id} = ?',
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
      RepoLogger.instance.log('getCachedSubmissionDetail: START for $submissionId');
      final db = await localDatabase.database;
      final results = await db.rawQuery('''
        SELECT s.*, u.full_name as student_name
        FROM assessment_submissions s
        LEFT JOIN users u ON u.id = s.user_id
        WHERE s.id = ? AND s.deleted_at IS NULL
      ''', [submissionId]);
      if (results.isEmpty) {
        RepoLogger.instance.log('getCachedSubmissionDetail: no submission row found for $submissionId');
        return null;
      }
      final sub = results.first;

      final answerRows = await db.rawQuery('''
        SELECT sa.id as answer_id, sa.question_id, sa.points as points_awarded,
               sa.overridden_by,
               aq.question_text, aq.question_type, aq.points as question_points,
               aq.order_index
        FROM submission_answers sa
        JOIN assessment_questions aq ON aq.id = sa.question_id
        WHERE sa.submission_id = ?
        ORDER BY aq.order_index ASC
      ''', [submissionId]);
      RepoLogger.instance.log('getCachedSubmissionDetail: found ${answerRows.length} answer rows for $submissionId');

      final List<SubmissionAnswerModel> answers = [];
      for (final row in answerRows) {
        final answerId = row['answer_id'] as String;
        final questionType = row['question_type'] as String;
        final questionText = enc.decryptField(row['question_text'] as String?) ?? '';

        final itemRows = await db.rawQuery('''
          SELECT sai.id, sai.choice_id, sai.answer_text, sai.is_correct, qc.choice_text
          FROM submission_answer_items sai
          LEFT JOIN question_choices qc ON qc.id = sai.choice_id
          WHERE sai.submission_answer_id = ?
        ''', [answerId]);

        List<SelectedChoiceModel>? selectedChoices;
        List<EnumerationAnswerModel>? enumerationAnswers;
        String? answerText;

        if (questionType == 'multiple_choice') {
          selectedChoices = itemRows
              .map((item) => SelectedChoiceModel(
                    choiceId: item['choice_id'] as String? ?? '',
                    choiceText: enc.decryptField(item['choice_text'] as String?) ?? '',
                    isCorrect: (item['is_correct'] as int?) == 1,
                  ))
              .toList();
        } else if (questionType == 'enumeration') {
          enumerationAnswers = itemRows
              .map((item) => EnumerationAnswerModel(
                    id: item['id'] as String,
                    answerText: enc.decryptField(item['answer_text'] as String?) ?? '',
                    isCorrect: (item['is_correct'] as int?) == 1,
                  ))
              .toList();
        } else {
          answerText = itemRows.isNotEmpty ? itemRows.first['answer_text'] as String? : null;
        }

        final pointsAwarded = (row['points_awarded'] as num?)?.toDouble() ?? 0.0;

        answers.add(SubmissionAnswerModel(
          id: answerId,
          questionId: row['question_id'] as String,
          questionText: questionText,
          questionType: questionType,
          points: (row['question_points'] as num?)?.toInt() ?? 0,
          answerText: answerText,
          selectedChoices: selectedChoices,
          enumerationAnswers: enumerationAnswers,
          isAutoCorrect: null,
          isOverrideCorrect: null,
          pointsAwarded: pointsAwarded,
          isPendingEssayGrade: false,
        ));
      }

      RepoLogger.instance.log('getCachedSubmissionDetail: built model with ${answers.length} answers for $submissionId');
      return SubmissionDetailModel(
        id: sub['id'] as String,
        assessmentId: sub['assessment_id'] as String? ?? '',
        studentId: sub['user_id'] as String? ?? '',
        studentName: enc.decryptField(sub['student_name'] as String?) ?? '',
        startedAt: DateTime.parse(sub['started_at'] as String),
        submittedAt: sub['submitted_at'] != null ? DateTime.parse(sub['submitted_at'] as String) : null,
        autoScore: (sub['earned_points'] as num?)?.toDouble() ?? 0.0,
        finalScore: (sub['earned_points'] as num?)?.toDouble() ?? 0.0,
        isSubmitted: sub['submitted_at'] != null,
        totalPoints: (sub['total_points'] as num?)?.toDouble() ?? 0.0,
        answers: answers,
      );
    } catch (e) {
      RepoLogger.instance.log('getCachedSubmissionDetail: ERROR for $submissionId: $e');
      throw CacheException('Failed to get cached submission detail: $e');
    }
  }

  @override
  Future<void> cacheSubmissionDetail(SubmissionDetailModel submission) async {
    try {
      RepoLogger.instance.log('cacheSubmissionDetail: START for ${submission.id}, answers=${submission.answers.length}');
      final db = await localDatabase.database;
      final now = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        await txn.insert(
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
            'cached_at': now,
            'needs_sync': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (submission.answers.isEmpty) {
          RepoLogger.instance.log('cacheSubmissionDetail: no answers to cache for ${submission.id}');
          return;
        }

        // Remove stale answer items before replacing answers
        final existingAnswers = await txn.query(
          'submission_answers',
          columns: ['id'],
          where: 'submission_id = ?',
          whereArgs: [submission.id],
        );
        for (final row in existingAnswers) {
          await txn.delete(
            'submission_answer_items',
            where: 'submission_answer_id = ?',
            whereArgs: [row['id']],
          );
        }
        await txn.delete(
          'submission_answers',
          where: 'submission_id = ?',
          whereArgs: [submission.id],
        );

        for (final answer in submission.answers) {
          await txn.insert(
            'submission_answers',
            {
              'id': answer.id,
              'submission_id': submission.id,
              'question_id': answer.questionId,
              'points': answer.pointsAwarded,
              'cached_at': now,
              'needs_sync': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          if (answer.selectedChoices != null) {
            for (final choice in answer.selectedChoices!) {
              await txn.insert(
                'submission_answer_items',
                {
                  'id': const Uuid().v4(),
                  'submission_answer_id': answer.id,
                  'choice_id': choice.choiceId,
                  'answer_text': null,
                  'is_correct': choice.isCorrect ? 1 : 0,
                  'cached_at': now,
                  'needs_sync': 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          } else if (answer.enumerationAnswers != null) {
            for (final enumAnswer in answer.enumerationAnswers!) {
              await txn.insert(
                'submission_answer_items',
                {
                  'id': const Uuid().v4(),
                  'submission_answer_id': answer.id,
                  'choice_id': null,
                  'answer_text': enumAnswer.answerText,
                  'is_correct': enumAnswer.isCorrect ? 1 : 0,
                  'cached_at': now,
                  'needs_sync': 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          } else if (answer.answerText != null) {
            await txn.insert(
              'submission_answer_items',
              {
                'id': const Uuid().v4(),
                'submission_answer_id': answer.id,
                'choice_id': null,
                'answer_text': answer.answerText,
                'is_correct': answer.pointsAwarded > 0 ? 1 : 0,
                'cached_at': now,
                'needs_sync': 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      RepoLogger.instance.log('cacheSubmissionDetail: DONE for ${submission.id}');
    } catch (e) {
      RepoLogger.instance.log('cacheSubmissionDetail: ERROR for ${submission.id}: $e');
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
        studentName: enc.decryptField(row['student_name'] as String?) ?? '',
        studentUsername: enc.decryptField(row['student_username'] as String?) ?? '',
        startedAt: DateTime.parse(row['started_at'] as String),
        submittedAt: row['submitted_at'] != null ? DateTime.parse(row['submitted_at'] as String) : null,
        autoScore: (row['earned_points'] as num?)?.toDouble() ?? 0.0,
        finalScore: (row['earned_points'] as num?)?.toDouble() ?? 0.0,
        totalPoints: (row['total_points'] as num?)?.toDouble() ?? 0.0,
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
    double? points,
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

          // Update points on the answer row so cached detail reflects the new score
          final answerUpdates = <String, dynamic>{
            SubmissionAnswersCols.overriddenAt: now.toIso8601String(),
          };
          if (points != null) {
            answerUpdates[SubmissionAnswersCols.points] = points;
          }
          await txn.update(
            'submission_answers',
            answerUpdates,
            where: 'id = ?',
            whereArgs: [answerId],
          );

          // Mark submission as needing sync
          await txn.update(
            'assessment_submissions',
            {
              CommonCols.needsSync: 1,
              CommonCols.updatedAt: now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [submissionId],
          );
        }

        final payload = <String, dynamic>{
          'answer_id': answerId,
          'is_correct': isCorrect,
        };
        if (points != null) {
          payload['points'] = points;
        }

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.overrideAnswer,
          payload: payload,
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

  @override
  Future<void> gradeEssayLocally({
    required String answerId,
    required double points,
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

          // Update points on the answer row
          await txn.update(
            'submission_answers',
            {
              SubmissionAnswersCols.points: points,
              SubmissionAnswersCols.overriddenAt: now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [answerId],
          );

          // Mark submission as needing sync
          await txn.update(
            'assessment_submissions',
            {
              CommonCols.needsSync: 1,
              CommonCols.updatedAt: now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [submissionId],
          );
        }

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.gradeEssay,
          payload: {
            'answer_id': answerId,
            'points': points,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to grade essay locally: $e');
    }
  }
}
