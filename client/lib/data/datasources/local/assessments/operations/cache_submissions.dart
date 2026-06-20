import 'package:likha/core/database/local_database.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<void> cacheSubmissions(
  LocalDatabase localDatabase,
  String assessmentId,
  List<SubmissionSummaryModel> submissions,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      for (final submission in submissions) {
        // DEFENSE: Use UPDATE instead of REPLACE to avoid CASCADE-deleting
        // nested submission_answers and submission_answer_items.
        // REPLACE does DELETE + INSERT, which triggers ON DELETE CASCADE.
        final updated = await txn.update(
          'assessment_submissions',
          {
            'assessment_id': assessmentId,
            'user_id': submission.studentId,
            'started_at': submission.startedAt.toIso8601String(),
            'submitted_at': submission.submittedAt?.toIso8601String(),
            'total_points': submission.totalPoints,
            'earned_points': submission.autoScore,
            'updated_at': DateTime.now().toIso8601String(),
            'cached_at': DateTime.now().toIso8601String(),
            'sync_status': SyncStatus.synced.dbValue,
          },
          where: 'id = ?',
          whereArgs: [submission.id],
        );

        // If this submission wasn't cached yet, insert it.
        // (This shouldn't affect answers because there were none to cascade.)
        if (updated == 0) {
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
              'sync_status': SyncStatus.synced.dbValue,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache submissions: $e');
  }
}
