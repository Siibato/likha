import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheCreatedAccount(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  UserModel account,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    final map = account.toMap();
    map['cached_at'] = now.toIso8601String();
    map['sync_status'] = SyncStatus.pending.dbValue;
    await db.transaction((txn) async {
      await txn.insert('users', map, conflictAlgorithm: ConflictAlgorithm.replace);
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.user,
        operation: SyncOperation.create,
        payload: map,
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  } catch (e) {
    throw CacheException('Failed to cache created account: $e');
  }
}
