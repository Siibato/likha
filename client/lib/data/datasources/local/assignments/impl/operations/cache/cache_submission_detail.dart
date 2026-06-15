import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheSubmissionDetailOp(
  LocalDatabase localDatabase,
  AssignmentSubmissionModel submission,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.insert(
        DbTables.assignmentSubmissions,
        {
          CommonCols.id: submission.id,
          AssignmentSubmissionsCols.assignmentId: submission.assignmentId,
          AssignmentSubmissionsCols.studentId: submission.studentId,
          AssignmentSubmissionsCols.status: submission.status,
          AssignmentSubmissionsCols.textContent: submission.textContent,
          AssignmentSubmissionsCols.submittedAt: submission.submittedAt?.toIso8601String(),
          // AssignmentSubmissionsCols.isLate field removed - no longer needed
          AssignmentSubmissionsCols.points: submission.score,
          AssignmentSubmissionsCols.feedback: submission.feedback,
          AssignmentSubmissionsCols.gradedBy: submission.gradedBy,
          AssignmentSubmissionsCols.gradedAt: submission.gradedAt?.toIso8601String(),
          CommonCols.createdAt: submission.createdAt.toIso8601String(),
          CommonCols.updatedAt: submission.updatedAt.toIso8601String(),
          CommonCols.cachedAt: now,
          CommonCols.needsSync: 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // Clear stale file metadata for this submission, then re-insert fresh list.
      // Actual file bytes on disk are untouched; getCachedSubmissionFilesOp
      // auto-repairs local_path from disk on the next read.
      await txn.delete(
        DbTables.submissionFiles,
        where: '${SubmissionFilesCols.submissionId} = ?',
        whereArgs: [submission.id],
      );
      for (final file in submission.files) {
        await txn.insert(DbTables.submissionFiles, {
          CommonCols.id: file.id,
          SubmissionFilesCols.submissionId: submission.id,
          SubmissionFilesCols.fileName: file.fileName,
          SubmissionFilesCols.fileType: file.fileType,
          SubmissionFilesCols.fileSize: file.fileSize,
          SubmissionFilesCols.uploadedAt: file.uploadedAt.toIso8601String(),
          SubmissionFilesCols.localPath: '',
          CommonCols.cachedAt: now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache submission detail: $e');
  }
}
