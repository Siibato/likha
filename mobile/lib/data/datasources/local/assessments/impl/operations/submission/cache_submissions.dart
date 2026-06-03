import 'package:likha/core/database/local_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<void> cacheSubmissionsOp(
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
