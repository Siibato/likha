import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<void> saveTos(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  TosModel tos, {
  Transaction? txn,
}) async {
  final now = DateTime.now();

  Future<void> doWrite(DatabaseExecutor executor) async {
    final map = {
      ...tos.toMap(),
      CommonCols.syncStatus: 'pending',
      CommonCols.cachedAt: now.toIso8601String(),
    };
    final inserted = await executor.insert(
      DbTables.tableOfSpecifications,
      map,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    if (inserted == 0) {
      await executor.update(
        DbTables.tableOfSpecifications,
        map,
        where: '${CommonCols.id} = ?',
        whereArgs: [tos.id],
      );
    }
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
        operation: SyncOperation.create,
        payload: tos.toMap(),
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: innerTxn);
    });
  }
}
