import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import '../auth_local_datasource_base.dart';

mixin AuthQueryMixin on AuthLocalDataSourceBase {
  @override
  Future<UserModel> getCachedCurrentUser() async {
    try {
      final db = await localDatabase.database;
      final result = await db.query(
        'users',
        where: 'is_search_cached = 0',
        limit: 1,
        orderBy: 'cached_at DESC',
      );
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
      final results = await db.query('users', orderBy: 'username ASC');
      if (results.isEmpty) throw CacheException('No cached accounts found');
      return results.map(UserModel.fromMap).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
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