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
    });
  } catch (e) {
    throw CacheException('Failed to cache submissions: $e');
  }
}
