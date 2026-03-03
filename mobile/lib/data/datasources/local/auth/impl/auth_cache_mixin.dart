import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:sqflite/sqflite.dart';
import '../auth_local_datasource_base.dart';

mixin AuthCacheMixin on AuthLocalDataSourceBase {
  @override
  Future<void> cacheCurrentUser(UserModel user) async {
    try {
      final db = await localDatabase.database;
      final map = user.toMap();
      map['cached_at'] = DateTime.now().toIso8601String();
      map['sync_status'] = 'synced';
      map['is_dirty'] = 0;
      await db.insert('users', map, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException('Failed to cache user: $e');
    }
  }

  @override
  Future<void> cacheAccounts(List<UserModel> accounts) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        for (final account in accounts) {
          final map = account.toMap();
          map['cached_at'] = DateTime.now().toIso8601String();
          map['sync_status'] = 'synced';
          map['is_dirty'] = 0;
          await txn.insert('users', map, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache accounts: $e');
    }
  }

  @override
  Future<void> cacheCreatedAccount(UserModel account) async {
    try {
      final db = await localDatabase.database;
      final map = account.toMap();
      map['cached_at'] = DateTime.now().toIso8601String();
      map['sync_status'] = 'pending';
      map['is_dirty'] = 1;
      await db.insert('users', map, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException('Failed to cache created account: $e');
    }
  }

  @override
  Future<void> cacheActivityLogs(List<ActivityLogModel> logs, String userId) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        for (final log in logs) {
          await txn.insert(
            'activity_logs',
            {
              'id': log.id,
              'user_id': log.userId,
              'action': log.action,
              'performed_by': log.performedBy,
              'details': log.details,
              'created_at': log.createdAt.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'cached_at': DateTime.now().toIso8601String(),
              'sync_status': 'synced',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache activity logs: $e');
    }
  }

  @override
  Future<void> clearActivityLogsForUser(String userId) async {
    try {
      final db = await localDatabase.database;
      await db.delete('activity_logs', where: 'user_id = ?', whereArgs: [userId]);
    } catch (e) {
      throw CacheException('Failed to clear activity logs: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      final db = await localDatabase.database;
      await db.delete('users');
      await db.delete('activity_logs');
      await db.delete('sync_metadata');
    } catch (e) {
      throw CacheException('Failed to clear auth cache: $e');
    }
  }
}