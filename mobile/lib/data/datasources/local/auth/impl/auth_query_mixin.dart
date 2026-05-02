import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import '../auth_local_datasource_base.dart';

mixin AuthQueryMixin on AuthLocalDataSourceBase {
  Map<String, dynamic> _decryptUserRow(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    m['full_name'] = enc.decryptField(row['full_name'] as String?);
    m['username'] = enc.decryptField(row['username'] as String?);
    return m;
 }

  @override
  Future<UserModel> getCachedCurrentUser([String? userId]) async {
    try {
      final db = await localDatabase.database;

      List<Map<String, dynamic>> result;
      if (userId != null) {
        // If userId provided, query for that specific user
        result = await db.query(
          DbTables.users,
          where: '${CommonCols.id} = ?',
          whereArgs: [userId],
          limit: 1,
        );
      } else {
        // Otherwise, return most recent user (backwards compatibility)
        result = await db.query(
          DbTables.users,
          where: '${CommonCols.id} != ""',
          limit: 1,
          orderBy: '${CommonCols.cachedAt} DESC',
        );
      }

      if (result.isEmpty) throw CacheException('No cached current user found');
      return UserModel.fromMap(_decryptUserRow(result.first));
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<List<UserModel>> getCachedAccounts() async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        DbTables.users,
        where: '${CommonCols.deletedAt} IS NULL',
        orderBy: '${UsersCols.username} ASC',
      );
      if (results.isEmpty) return [];
      return results.map((r) => UserModel.fromMap(_decryptUserRow(r))).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<UserModel> getCachedUser(String userId) async {
    try {
      final db = await localDatabase.database;
      final result = await db.query(
        DbTables.users,
        where: '${CommonCols.id} = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (result.isEmpty) throw CacheException('User not found in cache: $userId');
      return UserModel.fromMap(_decryptUserRow(result.first));
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to get cached user: $e');
    }
  }

  @override
  Future<List<ActivityLogModel>> getCachedActivityLogs(String userId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        DbTables.activityLogs,
        where: '${ActivityLogsCols.userId} = ?',
        whereArgs: [userId],
        orderBy: '${CommonCols.createdAt} DESC',
      );
      if (results.isEmpty) throw CacheException('No cached activity logs found for user: $userId');
      return results.map((row) {
        final decryptedRow = Map<String, dynamic>.from(row);
        decryptedRow['details'] = enc.decryptField(row['details'] as String?);
        return ActivityLogModel.fromMap(decryptedRow);
      }).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }
}