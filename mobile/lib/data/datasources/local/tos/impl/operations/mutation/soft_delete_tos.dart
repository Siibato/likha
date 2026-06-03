import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> softDeleteTosOp(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String tosId,
) async {
  final db = await localDatabase.database;
  final now = DateTime.now();
  await db.transaction((txn) async {
    await txn.update(
      DbTables.tableOfSpecifications,
      {
        CommonCols.deletedAt: now.toIso8601String(),
        CommonCols.updatedAt: now.toIso8601String(),
        CommonCols.needsSync: 1,
        CommonCols.cachedAt: now.toIso8601String(),
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [tosId],
    );
    await syncQueue.enqueue(SyncQueueEntry(
      id: const Uuid().v4(),
      entityType: SyncEntityType.tableOfSpecifications,
      operation: SyncOperation.delete,
      payload: {'id': tosId},
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 3,
      createdAt: now,
    ), txn: txn);
  });
}
