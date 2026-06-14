import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheAccounts(
  LocalDatabase localDatabase,
  List<UserModel> accounts,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      for (final account in accounts) {
        final map = account.toMap();
        map['cached_at'] = DateTime.now().toIso8601String();
        map['sync_status'] = SyncStatus.synced.dbValue;
        await txn.insert('users', map, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache accounts: $e');
  }
}
