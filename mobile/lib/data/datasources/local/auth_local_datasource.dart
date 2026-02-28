import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> getCachedCurrentUser();
  Future<void> cacheCurrentUser(UserModel user);
  Future<List<UserModel>> getCachedAccounts();
  Future<void> cacheAccounts(List<UserModel> accounts);
  Future<List<ActivityLogModel>> getCachedActivityLogs(String userId);
  Future<void> cacheActivityLogs(List<ActivityLogModel> logs, String userId);
  Future<void> clearActivityLogsForUser(String userId);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalDatabase _localDatabase;

  AuthLocalDataSourceImpl(this._localDatabase);

  @override
  Future<UserModel> getCachedCurrentUser() async {
    try {
      final db = await _localDatabase.database;
      final result = await db.query(
        'users',
        where: 'is_search_cached = 0',
        limit: 1,
        orderBy: 'cached_at DESC',
      );

      if (result.isEmpty) {
        throw CacheException('No cached current user found');
      }

      return UserModel.fromMap(result.first);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheCurrentUser(UserModel user) async {
    try {
      final db = await _localDatabase.database;
      final map = user.toMap();
      map['cached_at'] = DateTime.now().toIso8601String();
      map['sync_status'] = 'synced';
      map['is_dirty'] = 0;

      await db.insert(
        'users',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache user: $e');
    }
  }

  @override
  Future<List<UserModel>> getCachedAccounts() async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query('users', orderBy: 'username ASC');

      if (results.isEmpty) {
        throw CacheException('No cached accounts found');
      }

      return results.map(UserModel.fromMap).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheAccounts(List<UserModel> accounts) async {
    try {
      final db = await _localDatabase.database;
      await db.transaction((txn) async {
        for (final account in accounts) {
          final map = account.toMap();
          map['cached_at'] = DateTime.now().toIso8601String();
          map['sync_status'] = 'synced';
          map['is_dirty'] = 0;

          await txn.insert(
            'users',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache accounts: $e');
    }
  }

  @override
  Future<List<ActivityLogModel>> getCachedActivityLogs(String userId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'activity_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      if (results.isEmpty) {
        throw CacheException('No cached activity logs found for user: $userId');
      }

      return results.map((row) => ActivityLogModel.fromJson(row.cast<String, dynamic>())).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheActivityLogs(List<ActivityLogModel> logs, String userId) async {
    try {
      final db = await _localDatabase.database;
      await db.transaction((txn) async {
        for (final log in logs) {
          final map = {
            'id': log.id,
            'user_id': log.userId,
            'action': log.action,
            'performed_by': log.performedBy,
            'details': log.details,
            'created_at': log.createdAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'cached_at': DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          };

          await txn.insert(
            'activity_logs',
            map,
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
      final db = await _localDatabase.database;
      await db.delete(
        'activity_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw CacheException('Failed to clear activity logs: $e');
    }
  }
}
