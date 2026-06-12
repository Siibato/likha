import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<void> saveTos(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  TosModel tos,
) async {
  final db = await localDatabase.database;
  final now = DateTime.now();
  await db.transaction((txn) async {
    await txn.insert(
      DbTables.tableOfSpecifications,
      {
        ...tos.toMap(),
        CommonCols.needsSync: 1,
        CommonCols.cachedAt: now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueue.enqueue(SyncQueueEntry(
      id: const Uuid().v4(),
      entityType: SyncEntityType.tableOfSpecifications,
      operation: SyncOperation.create,
      payload: tos.toMap(),
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 3,
      createdAt: now,
    ), txn: txn);
  });
}
