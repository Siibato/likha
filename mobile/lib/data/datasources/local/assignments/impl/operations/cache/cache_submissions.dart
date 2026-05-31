import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';

Future<void> cacheSubmissionsOp(
  LocalDatabase localDatabase,
  String assignmentId,
  List<SubmissionListItemModel> submissions,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      for (final submission in submissions) {
        final map = {
          CommonCols.id: submission.id,
          AssignmentSubmissionsCols.assignmentId: assignmentId,
          AssignmentSubmissionsCols.studentId: submission.studentId,
          AssignmentSubmissionsCols.status: submission.status,
          AssignmentSubmissionsCols.submittedAt: submission.submittedAt?.toIso8601String(),
          // AssignmentSubmissionsCols.isLate field removed - no longer needed
          AssignmentSubmissionsCols.points: submission.score,
          CommonCols.createdAt: now.toIso8601String(),
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.needsSync: 0,
        };
        // Update-first pattern: only touch columns in the list API response, preserve text_content
        final updated = await txn.update(DbTables.assignmentSubmissions, map, where: '${CommonCols.id} = ?', whereArgs: [map[CommonCols.id]]);
        if (updated == 0) {
          await txn.insert(DbTables.assignmentSubmissions, map);
        }
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache submissions: $e');
  }
}
