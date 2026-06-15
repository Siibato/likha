import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> updateScoreOverride(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String scoreId,
  double? overrideScore, {
  Transaction? txn,
}) async {
  final now = DateTime.now();

  Future<void> doWrite(DatabaseExecutor executor) async {
    await executor.update(
      DbTables.gradeScores,
      {
        GradeScoresCols.overrideScore: overrideScore,
        CommonCols.updatedAt: now.toIso8601String(),
        CommonCols.cachedAt: now.toIso8601String(),
        CommonCols.syncStatus: 'pending',
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [scoreId],
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
        entityType: SyncEntityType.gradeScore,
        operation: overrideScore == null ? SyncOperation.clearOverride : SyncOperation.setOverride,
        payload: {'id': scoreId, if (overrideScore != null) 'override_score': overrideScore},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: innerTxn);
    });
  }
}
