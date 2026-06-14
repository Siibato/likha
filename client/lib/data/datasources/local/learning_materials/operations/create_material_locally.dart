import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:uuid/uuid.dart';

Future<LearningMaterialModel> createMaterialLocally(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String classId,
  String title,
  String description,
  String contentText,
) async {
  try {
    final db = await localDatabase.database;
    final id = const Uuid().v4();
    final now = DateTime.now();

    final material = LearningMaterialModel(
      id: id,
      classId: classId,
      title: title,
      description: description,
      contentText: contentText,
      orderIndex: 0,
      fileCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      final map = material.toMap();
      map[CommonCols.cachedAt] = now.toIso8601String();
      map[CommonCols.syncStatus] = 'pending';
      await txn.insert(DbTables.learningMaterials, map);

      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.learningMaterial,
        operation: SyncOperation.create,
        payload: {
          'id': id,
          'class_id': classId,
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

    return material;
  } catch (e) {
    throw CacheException('Failed to create material locally: $e');
  }
}
