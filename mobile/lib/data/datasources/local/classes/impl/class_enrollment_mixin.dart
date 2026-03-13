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
            'joined_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'removed_at': null,
            'cached_at': now.toIso8601String(),
            'needs_sync': 1,
          },
        );

        await txn.rawUpdate(
          'UPDATE classes SET student_count = (SELECT COUNT(*) FROM class_participants WHERE class_id = ? AND removed_at IS NULL), updated_at = ? WHERE id = ?',
          [classId, now.toIso8601String(), classId],
        );
      });
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
            'needs_sync': 1,
            'updated_at': now.toIso8601String(),
          },
          where: 'class_id = ? AND user_id = ? AND removed_at IS NULL',
          whereArgs: [classId, studentId],
        );

        await txn.rawUpdate(
          'UPDATE classes SET student_count = (SELECT COUNT(*) FROM class_participants WHERE class_id = ? AND removed_at IS NULL), updated_at = ? WHERE id = ?',
          [classId, now.toIso8601String(), classId],
        );
      });
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
        where: 'class_id = ? AND removed_at IS NULL',
        whereArgs: [classId],
      );
      return results.map((row) => row['user_id'] as String).toSet();
    } catch (e) {
      throw CacheException('Failed to get enrolled student IDs: $e');
    }
  }
}
