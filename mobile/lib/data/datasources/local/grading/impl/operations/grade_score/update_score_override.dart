import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> updateScoreOverrideOp(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String scoreId,
  double? overrideScore,
) async {
  final db = await localDatabase.database;
  final now = DateTime.now();
  await db.transaction((txn) async {
    await txn.update(
      DbTables.gradeScores,
      {
        GradeScoresCols.overrideScore: overrideScore,
        CommonCols.updatedAt: now.toIso8601String(),
        CommonCols.cachedAt: now.toIso8601String(),
        CommonCols.needsSync: 1,
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [scoreId],
    );
    await syncQueue.enqueue(SyncQueueEntry(
      id: const Uuid().v4(),
      entityType: SyncEntityType.gradeScore,
      operation: SyncOperation.setOverride,
      payload: {'id': scoreId, 'override_score': overrideScore},
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 3,
      createdAt: now,
    ), txn: txn);
  });
}
