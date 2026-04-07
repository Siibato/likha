import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:sqflite/sqflite.dart';
import '../assignment_local_datasource_base.dart';

mixin AssignmentCacheMixin on AssignmentLocalDataSourceBase {
  @override
  Future<void> cacheAssignments(List<AssignmentModel> assignments) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        for (final assignment in assignments) {
          final map = assignment.toMap();
          map[CommonCols.cachedAt] = DateTime.now().toIso8601String();
          map[CommonCols.needsSync] = 0;
          // Use update-first pattern to avoid CASCADE DELETE on assignment_submissions
          final updated = await txn.update(DbTables.assignments, map, where: '${CommonCols.id} = ?', whereArgs: [map[CommonCols.id]]);
          if (updated == 0) {
            await txn.insert(DbTables.assignments, map);
          }
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache assignments: $e');
    }
  }

  @override
  Future<void> cacheAssignmentDetail(AssignmentModel assignment) async {
    try {
      final db = await localDatabase.database;
      final map = assignment.toMap();
      map['cached_at'] = DateTime.now().toIso8601String();
      map['needs_sync'] = 0;
      // Use update-first pattern to avoid CASCADE DELETE on assignment_submissions
      final updated = await db.update(DbTables.assignments, map, where: '${CommonCols.id} = ?', whereArgs: [map[CommonCols.id]]);
      if (updated == 0) {
        await db.insert(DbTables.assignments, map);
      }
    } catch (e) {
      throw CacheException('Failed to cache assignment detail: $e');
    }
  }

  @override
  Future<void> cacheSubmissions(String assignmentId, List<SubmissionListItemModel> submissions) async {
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
            AssignmentSubmissionsCols.isLate: submission.isLate ? 1 : 0,
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

  @override
  Future<void> cacheSubmissionDetail(AssignmentSubmissionModel submission) async {
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
            AssignmentSubmissionsCols.isLate: submission.isLate ? 1 : 0,
            AssignmentSubmissionsCols.points: submission.score,
            AssignmentSubmissionsCols.feedback: submission.feedback,
            AssignmentSubmissionsCols.gradedAt: submission.gradedAt?.toIso8601String(),
            CommonCols.createdAt: submission.createdAt.toIso8601String(),
            CommonCols.updatedAt: submission.updatedAt.toIso8601String(),
            CommonCols.cachedAt: now,
            CommonCols.needsSync: 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        // Cache submission files metadata
        for (final file in submission.files) {
          final existing = await txn.query(
            DbTables.submissionFiles,
            where: '${CommonCols.id} = ?',
            whereArgs: [file.id],
          );
          if (existing.isEmpty) {
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
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache submission detail: $e');
    }
  }

  @override
  Future<void> cacheSubmissionFile(String submissionId, SubmissionFileModel file) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now().toIso8601String();
      final existing = await db.query(
        DbTables.submissionFiles,
        where: '${CommonCols.id} = ?',
        whereArgs: [file.id],
      );
      if (existing.isEmpty) {
        await db.insert(DbTables.submissionFiles, {
          CommonCols.id: file.id,
          SubmissionFilesCols.submissionId: submissionId,
          SubmissionFilesCols.fileName: file.fileName,
          SubmissionFilesCols.fileType: file.fileType,
          SubmissionFilesCols.fileSize: file.fileSize,
          SubmissionFilesCols.uploadedAt: file.uploadedAt.toIso8601String(),
          SubmissionFilesCols.localPath: '',
          CommonCols.cachedAt: now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    } catch (e) {
      throw CacheException('Failed to cache submission file: $e');
    }
  }
}