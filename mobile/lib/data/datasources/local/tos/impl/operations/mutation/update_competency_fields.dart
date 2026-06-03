import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> updateCompetencyFieldsOp(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String competencyId,
  Map<String, dynamic> data,
) async {
  final db = await localDatabase.database;
  final now = DateTime.now();
  // Map API/UI key names to the local SQLite column names.
  final localData = {
    for (final e in data.entries)
      (e.key == 'days_taught' ? 'time_units_taught' : e.key): e.value,
  };
  await db.transaction((txn) async {
    await txn.update(
      DbTables.tosCompetencies,
      {
        ...localData,
        CommonCols.updatedAt: now.toIso8601String(),
        CommonCols.needsSync: 1,
        CommonCols.cachedAt: now.toIso8601String(),
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [competencyId],
    );
    await syncQueue.enqueue(SyncQueueEntry(
      id: const Uuid().v4(),
      entityType: SyncEntityType.tosCompetency,
      operation: SyncOperation.update,
      payload: {'id': competencyId, ...data},
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 3,
      createdAt: now,
    ), txn: txn);
  });
}
