import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';

Future<void> updateClassLocallyOp(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String classId,
  String title,
  String description,
  bool? isAdvisory,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        DbTables.classes,
        {
          ClassesCols.title: title,
          ClassesCols.description: description,
          if (isAdvisory != null) ClassesCols.isAdvisory: isAdvisory ? 1 : 0,
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [classId],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.classEntity,
        operation: SyncOperation.update,
        payload: {
          'id': classId,
          'title': title,
          'description': description,
          if (isAdvisory != null) 'is_advisory': isAdvisory,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  } catch (e) {
    throw CacheException('Failed to update class locally: $e');
  }
}
