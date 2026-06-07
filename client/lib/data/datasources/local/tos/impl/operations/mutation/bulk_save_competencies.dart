import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<void> bulkSaveCompetenciesOp(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  List<CompetencyModel> competencies,
) async {
  final db = await localDatabase.database;
  final now = DateTime.now();
  await db.transaction((txn) async {
    for (final comp in competencies) {
      await txn.insert(
        DbTables.tosCompetencies,
        {
          ...comp.toMap(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    // Enqueue a single bulk operation with all competencies
    await syncQueue.enqueue(SyncQueueEntry(
      id: const Uuid().v4(),
      entityType: SyncEntityType.tosCompetency,
      operation: SyncOperation.create,
      payload: {
        'competencies': competencies.map((c) => c.toMap()).toList(),
      },
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 3,
      createdAt: now,
    ), txn: txn);
  });
}
