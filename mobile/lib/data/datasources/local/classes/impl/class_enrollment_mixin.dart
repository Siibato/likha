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
      final enrollmentId = const Uuid().v4();
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.insert(
          'class_enrollments',
          {
            'id': enrollmentId,
            'class_id': classId,
            'student_id': student.id,
            'username': student.username,
            'full_name': student.fullName,
            'role': student.role,
            'account_status': student.accountStatus,
            'is_active': student.isActive ? 1 : 0,
            'enrolled_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
            'sync_status': 'pending',
            'local_id': enrollmentId,
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
      return enrollmentId;
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
        await txn.delete(
          'class_enrollments',
          where: 'class_id = ? AND student_id = ?',
          whereArgs: [classId, studentId],
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
    } catch (e) {
      throw CacheException('Failed to remove student locally: $e');
    }
  }

  @override
  Future<Set<String>> getEnrolledStudentIds(String classId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'class_enrollments',
        columns: ['student_id'],
        where: 'class_id = ?',
        whereArgs: [classId],
      );
      return results.map((row) => row['student_id'] as String).toSet();
    } catch (e) {
      throw CacheException('Failed to get enrolled student IDs: $e');
    }
  }
}