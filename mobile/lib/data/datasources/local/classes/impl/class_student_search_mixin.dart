import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:sqflite/sqflite.dart';
import '../class_local_datasource_base.dart';

mixin ClassStudentSearchMixin on ClassLocalDataSourceBase {
  Map<String, dynamic> _decryptUserRow(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    m['username'] = enc.decryptField(row['username'] as String?);
    m['full_name'] = enc.decryptField(row['full_name'] as String?);
    return m;
  }
  @override
  Future<UserModel?> getStudentById(String studentId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        DbTables.users,
        where: '${CommonCols.id} = ?',
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
            DbTables.users,
            {
              CommonCols.id: student.id,
              UsersCols.username: student.username,
              UsersCols.fullName: student.fullName,
              UsersCols.role: student.role,
              UsersCols.accountStatus: student.accountStatus,
              UsersCols.activatedAt: student.activatedAt?.toIso8601String(),
              CommonCols.createdAt: student.createdAt.toIso8601String(),
              CommonCols.updatedAt: DateTime.now().toIso8601String(),
              CommonCols.deletedAt: student.deletedAt?.toIso8601String(),
              CommonCols.cachedAt: DateTime.now().toIso8601String(),
              CommonCols.needsSync: 0,
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
        DbTables.users,
        where: '(${UsersCols.username} LIKE ? OR ${UsersCols.fullName} LIKE ?) AND ${UsersCols.role} = ?',
        whereArgs: ['%$query%', '%$query%', 'student'],
        orderBy: '${UsersCols.fullName} ASC',
      );
      return results.map((r) => UserModel.fromMap(_decryptUserRow(r))).toList();
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
        FROM ${DbTables.classParticipants} cp
        JOIN ${DbTables.users} u ON u.id = cp.user_id
        WHERE cp.class_id = ? AND cp.removed_at IS NULL
        ORDER BY u.full_name ASC
      ''', [classId]);

      return rows.map((row) {
        final decryptedRow = _decryptUserRow(row);
        final accountStatus = decryptedRow['account_status'] as String?;
        final isActive = accountStatus != null &&
            accountStatus != 'locked' &&
            accountStatus != 'deactivated';

        return UserModel(
          id: decryptedRow['user_id'] as String,
          username: decryptedRow['username'] as String? ?? '',
          fullName: decryptedRow['full_name'] as String? ?? '',
          role: decryptedRow['role'] as String? ?? '',
          accountStatus: accountStatus ?? 'active',
          isActive: isActive,
          activatedAt: decryptedRow['activated_at'] != null
              ? DateTime.parse(decryptedRow['activated_at'] as String)
              : null,
          createdAt: decryptedRow['created_at'] != null
              ? DateTime.parse(decryptedRow['created_at'] as String)
              : DateTime.parse(decryptedRow['joined_at'] as String),
        );
      }).toList();
    } catch (e) {
      throw CacheException('Failed to get participants: $e');
    }
  }
}
