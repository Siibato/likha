import 'dart:io';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../learning_material_local_datasource_base.dart';

mixin LearningMaterialMutationMixin on LearningMaterialLocalDataSourceBase {
  @override
  Future<LearningMaterialModel> createMaterialLocally({
    required String classId,
    required String title,
    required String description,
    required String contentText,
  }) async {
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
        map['cached_at'] = now.toIso8601String();
        map['sync_status'] = 'pending';
        map['is_offline_mutation'] = 1;
        await txn.insert('learning_materials', map);

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
          maxRetries: 5,
          createdAt: now,
        ), txn: txn);
      });

      return material;
    } catch (e) {
      throw CacheException('Failed to create material locally: $e');
    }
  }

  @override
  Future<void> updateMaterialLocally({
    required String materialId,
    required String title,
    required String description,
    required String contentText,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();

      await db.transaction((txn) async {
        await txn.update(
          'learning_materials',
          {
            'title': title,
            'description': description,
            'content_text': contentText,
            'updated_at': now.toIso8601String(),
            'is_offline_mutation': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
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
          maxRetries: 5,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to update material locally: $e');
    }
  }

  @override
  Future<void> stageMaterialFileForUpload({
    required String materialId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      final fileId = const Uuid().v4();

      final appDir = await getApplicationDocumentsDirectory();
      final uploadDir = Directory('${appDir.path}/offline_uploads');
      if (!await uploadDir.exists()) await uploadDir.create(recursive: true);

      final sourceFile = File(localPath);
      if (!await sourceFile.exists()) {
        throw CacheException('Source file does not exist: $localPath');
      }

      final stagedPath = '${uploadDir.path}/${fileId}_$fileName';
      await sourceFile.copy(stagedPath);

      await db.insert(
        'material_files',
        {
          'id': fileId,
          'material_id': materialId,
          'file_name': fileName,
          'file_type': fileType,
          'file_size': fileSize,
          'uploaded_at': now.toIso8601String(),
          'local_path': stagedPath,
          'is_cached': 0,
          'cached_at': now.toIso8601String(),
        },
      );

      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.materialFile,
        operation: SyncOperation.upload,
        payload: {
          'file_id': fileId,
          'material_id': materialId,
          'local_path': stagedPath,
          'file_name': fileName,
          'file_type': fileType,
          'file_size': fileSize,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: now,
      ));
    } catch (e) {
      throw CacheException('Failed to stage material file for upload: $e');
    }
  }
}