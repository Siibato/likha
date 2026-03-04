import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
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
          map['cached_at'] = DateTime.now().toIso8601String();
          map['sync_status'] = 'synced';
          map['is_offline_mutation'] = 0;
          await txn.insert('assignments', map, conflictAlgorithm: ConflictAlgorithm.replace);
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
      map['sync_status'] = 'synced';
      map['is_offline_mutation'] = 0;
      await db.insert('assignments', map, conflictAlgorithm: ConflictAlgorithm.replace);
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
          await txn.insert(
            'assignment_submissions',
            {
              'id': submission.id,
              'assignment_id': assignmentId,
              'student_id': submission.studentId,
              'student_name': submission.studentName,
              'status': submission.status,
              'submitted_at': submission.submittedAt?.toIso8601String(),
              'is_late': submission.isLate ? 1 : 0,
              'score': submission.score,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
              'cached_at': now.toIso8601String(),
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
  Future<void> cacheSubmissionDetail(AssignmentSubmissionModel submission) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now().toIso8601String();
      await db.transaction((txn) async {
        await txn.insert(
          'assignment_submissions',
          {
            'id': submission.id,
            'assignment_id': submission.assignmentId,
            'student_id': submission.studentId,
            'student_name': submission.studentName,
            'status': submission.status,
            'text_content': submission.textContent,
            'submitted_at': submission.submittedAt?.toIso8601String(),
            'is_late': submission.isLate ? 1 : 0,
            'score': submission.score,
            'feedback': submission.feedback,
            'graded_at': submission.gradedAt?.toIso8601String(),
            'created_at': submission.createdAt.toIso8601String(),
            'updated_at': submission.updatedAt.toIso8601String(),
            'cached_at': now,
            'sync_status': 'synced',
            'is_offline_mutation': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        // Cache submission files metadata
        for (final file in submission.files) {
          final existing = await txn.query(
            'submission_files',
            columns: ['is_local_only'],
            where: 'id = ?',
            whereArgs: [file.id],
          );
          if (existing.isEmpty) {
            await txn.insert('submission_files', {
              'id': file.id,
              'local_id': file.id,
              'submission_id': submission.id,
              'file_name': file.fileName,
              'file_type': file.fileType,
              'file_size': file.fileSize,
              'uploaded_at': file.uploadedAt.toIso8601String(),
              'local_path': null,
              'is_local_only': 0,
              'cached_at': now,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
          // Don't overwrite server-side fields if is_local_only (pending upload)
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache submission detail: $e');
    }
  }
}