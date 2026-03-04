import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:sqflite/sqflite.dart';
import '../class_local_datasource_base.dart';

mixin ClassStudentSearchMixin on ClassLocalDataSourceBase {
  @override
  Future<UserModel?> getStudentById(String studentId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [studentId],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return UserModel.fromMap(results.first);
    } catch (e) {
      throw CacheException('Failed to get student by id: $e');
    }
  }

  @override
  Future<void> cacheSearchStudents(List<UserModel> students) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        for (final student in students) {
          final existing = await txn.query(
            'users',
            where: 'id = ?',
            whereArgs: [student.id],
            limit: 1,
          );
          if (existing.isNotEmpty) continue; // never overwrite logged-in user

          await txn.insert(
            'users',
            {
              'id': student.id,
              'username': student.username,
              'full_name': student.fullName,
              'role': student.role,
              'account_status': student.accountStatus,
              'is_active': student.isActive ? 1 : 0,
              'activated_at': student.activatedAt?.toIso8601String(),
              'created_at': student.createdAt.toIso8601String(),
              'cached_at': DateTime.now().toIso8601String(),
              'is_offline_mutation': 0,
              'sync_status': 'synced',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache search students: $e');
    }
  }

  @override
  Future<List<UserModel>> searchCachedStudents(String query) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'users',
        where: '(username LIKE ? OR full_name LIKE ?)',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'full_name ASC',
      );
      return results.map(UserModel.fromMap).toList();
    } catch (e) {
      throw CacheException('Failed to search cached students: $e');
    }
  }

  @override
  Future<List<UserModel>> getCachedEnrolledStudents(String classId) async {
    try {
      final db = await localDatabase.database;
      final rows = await db.query(
        'class_enrollments',
        where: 'class_id = ? AND deleted_at IS NULL',
        whereArgs: [classId],
        orderBy: 'full_name ASC',
      );
      return rows.map((row) => UserModel(
        id: row['student_id'] as String,
        username: row['username'] as String,
        fullName: row['full_name'] as String,
        role: row['role'] as String,
        accountStatus: row['account_status'] as String,
        isActive: (row['is_active'] as int) == 1,
        activatedAt: null,
        createdAt: DateTime.parse(row['enrolled_at'] as String),
      )).toList();
    } catch (e) {
      throw CacheException('Failed to get enrolled students: $e');
    }
  }
}