import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import '../auth_local_datasource_base.dart';

mixin AuthQueryMixin on AuthLocalDataSourceBase {
  @override
  Future<UserModel> getCachedCurrentUser([String? userId]) async {
    try {
      final db = await localDatabase.database;

      List<Map<String, dynamic>> result;
      if (userId != null) {
        // If userId provided, query for that specific user
        result = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
          limit: 1,
        );
      } else {
        // Otherwise, return most recent user (backwards compatibility)
        result = await db.query(
          'users',
          where: 'id != ""',
          limit: 1,
          orderBy: 'cached_at DESC',
        );
      }

      if (result.isEmpty) throw CacheException('No cached current user found');
      return UserModel.fromMap(result.first);
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
        'users',
        orderBy: 'username ASC'
        );
      if (results.isEmpty) throw CacheException('No cached accounts found');
      return results.map(UserModel.fromMap).toList();
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
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (result.isEmpty) throw CacheException('User not found in cache: $userId');
      return UserModel.fromMap(result.first);
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
        'activity_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      if (results.isEmpty) throw CacheException('No cached activity logs found for user: $userId');
      return results.map((row) => ActivityLogModel.fromJson(row.cast<String, dynamic>())).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }
}