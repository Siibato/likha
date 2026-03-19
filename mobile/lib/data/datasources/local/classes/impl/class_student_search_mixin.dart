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
          // Use ConflictAlgorithm.replace to update existing student data
          // This ensures stale data from prior sync/searches is updated
          await txn.insert(
            'users',
            {
              'id': student.id,
              'username': student.username,
              'full_name': student.fullName,
              'role': student.role,
              'account_status': student.accountStatus,
              'activated_at': student.activatedAt?.toIso8601String(),
              'created_at': student.createdAt.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'deleted_at': student.deletedAt?.toIso8601String(),
              'cached_at': DateTime.now().toIso8601String(),
              'needs_sync': 0,
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
        where: '(username LIKE ? OR full_name LIKE ?) AND role = ?',
        whereArgs: ['%$query%', '%$query%', 'student'],
        orderBy: 'full_name ASC',
      );
      return results.map(UserModel.fromMap).toList();
    } catch (e) {
      throw CacheException('Failed to search cached students: $e');
    }
  }

  @override
  Future<List<UserModel>> getCachedParticipants(String classId) async {
    try {
      final db = await localDatabase.database;
      // v18: Join with users table to get student details
      final rows = await db.rawQuery('''
        SELECT cp.id, cp.class_id, cp.user_id, cp.joined_at,
               u.username, u.full_name, u.role, u.account_status, u.activated_at, u.created_at
        FROM class_participants cp
        JOIN users u ON u.id = cp.user_id
        WHERE cp.class_id = ? AND cp.removed_at IS NULL
        ORDER BY u.full_name ASC
      ''', [classId]);

      return rows.map((row) {
        final accountStatus = row['account_status'] as String?;
        final isActive = accountStatus != null &&
            accountStatus != 'locked' &&
            accountStatus != 'deactivated';

        return UserModel(
          id: row['user_id'] as String,
          username: row['username'] as String? ?? '',
          fullName: row['full_name'] as String? ?? '',
          role: row['role'] as String? ?? '',
          accountStatus: accountStatus ?? 'active',
          isActive: isActive,
          activatedAt: row['activated_at'] != null
              ? DateTime.parse(row['activated_at'] as String)
              : null,
          createdAt: row['created_at'] != null
              ? DateTime.parse(row['created_at'] as String)
              : DateTime.parse(row['joined_at'] as String),
        );
      }).toList();
    } catch (e) {
      throw CacheException('Failed to get participants: $e');
    }
  }
}
