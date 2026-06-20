import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

Future<void> cacheSubmissionDetail(
  LocalDatabase localDatabase,
  SubmissionDetailModel submission,
) async {
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
          'sync_status': SyncStatus.synced.dbValue,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (submission.answers.isEmpty) {
        RepoLogger.instance.log('cacheSubmissionDetail: no answers to cache for ${submission.id}');
        return;
      }

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
            'sync_status': SyncStatus.synced.dbValue,
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
                'sync_status': SyncStatus.synced.dbValue,
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
                'sync_status': SyncStatus.synced.dbValue,
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
              'sync_status': SyncStatus.synced.dbValue,
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
