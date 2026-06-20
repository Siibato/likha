import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<void> saveCompetency(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  CompetencyModel competency, {
  Transaction? txn,
}) async {
  final now = DateTime.now();

  Future<void> doWrite(DatabaseExecutor executor) async {
    final map = {
      ...competency.toMap(),
      CommonCols.syncStatus: 'pending',
      CommonCols.cachedAt: now.toIso8601String(),
    };
    final inserted = await executor.insert(
      DbTables.tosCompetencies,
      map,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    if (inserted == 0) {
      await executor.update(
        DbTables.tosCompetencies,
        map,
        where: '${CommonCols.id} = ?',
        whereArgs: [competency.id],
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
        entityType: SyncEntityType.tosCompetency,
        operation: SyncOperation.create,
        payload: competency.toMap(),
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: innerTxn);
    });
  }
}
