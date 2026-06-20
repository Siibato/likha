import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';

Future<void> markAssignmentPublished(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String assignmentId, {
  String? queueEntryId,
}) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        DbTables.assignments,
        {
          AssignmentsCols.isPublished: 1,
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.syncStatus: 'pending',
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [assignmentId],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: queueEntryId ?? const Uuid().v4(),
        entityType: SyncEntityType.assignment,
        operation: SyncOperation.update,
        payload: {'id': assignmentId, 'action': 'publish'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  } catch (e) {
    throw CacheException('Failed to mark assignment as published locally: $e');
  }
}
