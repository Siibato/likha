import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart'
    show SubmissionListItemModel;
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
}