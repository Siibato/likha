import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:uuid/uuid.dart';

Future<void> updateMaterialLocally(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String materialId,
  String title,
  String description,
  String contentText,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      await txn.update(
        DbTables.learningMaterials,
        {
          LearningMaterialsCols.title: title,
          LearningMaterialsCols.description: description,
          LearningMaterialsCols.contentText: contentText,
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [materialId],
      );

      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.learningMaterial,
        operation: SyncOperation.update,
        payload: {
          'id': materialId,
          'title': title,
          'description': description,
          'content_text': contentText,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  } catch (e) {
    throw CacheException('Failed to update material locally: $e');
  }
}
