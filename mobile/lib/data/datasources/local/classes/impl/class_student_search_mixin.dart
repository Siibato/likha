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
        where: 'id = ? AND is_search_cached = 1',
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
            where: 'id = ? AND is_search_cached = 0',
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
              'is_dirty': 0,
              'sync_status': 'synced',
              'is_search_cached': 1,
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
        where: 'is_search_cached = 1 AND (username LIKE ? OR full_name LIKE ?)',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'full_name ASC',
      );
      return results.map(UserModel.fromMap).toList();
    } catch (e) {
      throw CacheException('Failed to search cached students: $e');
    }
  }
}