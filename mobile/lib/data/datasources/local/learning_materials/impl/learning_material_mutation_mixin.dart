import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/database/db_schema.dart';
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
        map[CommonCols.cachedAt] = now.toIso8601String();
        map[CommonCols.needsSync] = 1;
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

  @override
  Future<void> deleteMaterialLocally(String materialId) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.update(
          DbTables.learningMaterials,
          {
            CommonCols.deletedAt: now.toIso8601String(),
            CommonCols.needsSync: 1,
            CommonCols.updatedAt: now.toIso8601String(),
          },
          where: '${CommonCols.id} = ?',
          whereArgs: [materialId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.delete,
          payload: {'id': materialId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to delete material locally: $e');
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
    if (kIsWeb) throw CacheException('File staging not supported on web');
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

      await db.transaction((txn) async {
        await txn.insert(
          DbTables.materialFiles,
          {
            CommonCols.id: fileId,
            MaterialFilesCols.materialId: materialId,
            MaterialFilesCols.fileName: fileName,
            MaterialFilesCols.fileType: fileType,
            MaterialFilesCols.fileSize: fileSize,
            MaterialFilesCols.localPath: stagedPath,
            MaterialFilesCols.uploadedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.needsSync: 1,
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
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to stage material file for upload: $e');
    }
  }

  @override
  Future<void> deleteMaterialFileLocally(String fileId) async {
    try {
      final db = await localDatabase.database;
      await db.update(
        DbTables.materialFiles,
        {CommonCols.deletedAt: DateTime.now().toIso8601String()},
        where: '${CommonCols.id} = ?',
        whereArgs: [fileId],
      );
    } catch (e) {
      throw CacheException('Failed to delete material file locally: $e');
    }
  }
}