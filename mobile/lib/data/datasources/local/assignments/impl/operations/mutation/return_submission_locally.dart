import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';

Future<void> returnSubmissionLocallyOp(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String submissionId,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        DbTables.assignmentSubmissions,
        {
          AssignmentSubmissionsCols.status: DbValues.statusReturned,
          CommonCols.needsSync: 1,
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [submissionId],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assignmentSubmission,
        operation: SyncOperation.update,
        payload: {'id': submissionId, 'action': 'return'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  } catch (e) {
    throw CacheException('Failed to return submission locally: $e');
  }
}
