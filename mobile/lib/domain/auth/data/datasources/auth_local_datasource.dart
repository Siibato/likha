import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/domain/auth/data/models/user_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> getCachedCurrentUser();
  Future<void> cacheCurrentUser(UserModel user);
  Future<List<UserModel>> getCachedAccounts();
  Future<void> cacheAccounts(List<UserModel> accounts);
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
}
