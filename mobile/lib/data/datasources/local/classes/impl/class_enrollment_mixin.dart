import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:uuid/uuid.dart';
import '../class_local_datasource_base.dart';

mixin ClassEnrollmentMixin on ClassLocalDataSourceBase {
  @override
  Future<String> addStudentLocally({
    required String classId,
    required UserModel student,
  }) async {
    try {
      final db = await localDatabase.database;
      final participantId = const Uuid().v4();
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.insert(
          'class_participants',
          {
            'id': participantId,
            'class_id': classId,
            'user_id': student.id,
            'username': student.username,
            'full_name': student.fullName,
            'role': 'student',
            'account_status': student.accountStatus,
            'joined_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'removed_at': null,
            'cached_at': now.toIso8601String(),
            'sync_status': 'pending',
            'is_offline_mutation': 1,
            'local_id': participantId,
          },
        );
        await txn.update(
          'classes',
          {
            'is_offline_mutation': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [classId],
        );
      });
      // Increment student_count after transaction completes
      await db.rawUpdate(
        'UPDATE classes SET student_count = student_count + 1 WHERE id = ?',
        [classId],
      );
      return participantId;
    } catch (e) {
      throw CacheException('Failed to add student locally: $e');
    }
  }

  @override
  Future<void> removeStudentLocally({
    required String classId,
    required String studentId,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        // Soft delete: set removed_at instead of hard delete
        await txn.update(
          'class_participants',
          {
            'removed_at': now.toIso8601String(),
            'is_offline_mutation': 1,
            'sync_status': 'pending',
          },
          where: 'class_id = ? AND user_id = ? AND role = ?',
          whereArgs: [classId, studentId, 'student'],
        );
        await txn.update(
          'classes',
          {
            'is_offline_mutation': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [classId],
        );
      });
      // Recompute student_count from actual class_participants after removal
      await db.rawUpdate(
        '''UPDATE classes SET student_count = (
          SELECT COUNT(*) FROM class_participants
          WHERE class_id = ? AND role = 'student' AND removed_at IS NULL
        ) WHERE id = ?''',
        [classId, classId],
      );
    } catch (e) {
      throw CacheException('Failed to remove student locally: $e');
    }
  }

  @override
  Future<Set<String>> getEnrolledStudentIds(String classId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'class_participants',
        columns: ['user_id'],
        where: 'class_id = ? AND role = ? AND removed_at IS NULL',
        whereArgs: [classId, 'student'],
      );
      return results.map((row) => row['user_id'] as String).toSet();
    } catch (e) {
      throw CacheException('Failed to get enrolled student IDs: $e');
    }
  }
}