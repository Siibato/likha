import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> softDeleteTos(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String tosId, {
  Transaction? txn,
}) async {
  final now = DateTime.now();

  Future<void> doWrite(DatabaseExecutor executor) async {
    await executor.update(
      DbTables.tableOfSpecifications,
      {
        CommonCols.deletedAt: now.toIso8601String(),
        CommonCols.updatedAt: now.toIso8601String(),
        CommonCols.syncStatus: 'pending',
        CommonCols.cachedAt: now.toIso8601String(),
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [tosId],
    );
  }

  if (txn != null) {
    await doWrite(txn);
  } else {
    final db = await localDatabase.database;
    await db.transaction((innerTxn) async {
      await doWrite(innerTxn);
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tableOfSpecifications,
        operation: SyncOperation.delete,
        payload: {'id': tosId},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: innerTxn);
    });
  }
}
