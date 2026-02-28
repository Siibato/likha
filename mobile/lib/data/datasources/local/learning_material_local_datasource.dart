import 'dart:io';

import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/compression_util.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

abstract class LearningMaterialLocalDataSource {
  Future<List<LearningMaterialModel>> getCachedMaterials(String classId);
  Future<LearningMaterialModel> getCachedMaterialDetail(String materialId);
  Future<void> cacheMaterials(List<LearningMaterialModel> materials);
  Future<void> cacheMaterialDetail(LearningMaterialModel material);
  Future<void> cacheFile(String fileId, String fileName, List<int> bytes);
  Future<List<int>> getCachedFile(String fileId);
  Future<bool> isFileCached(String fileId);
  Future<LearningMaterialModel> createMaterialLocally({
    required String classId,
    required String title,
    required String description,
    required String contentText,
  });
  Future<void> updateMaterialLocally({
    required String materialId,
    required String title,
    required String description,
    required String contentText,
  });
  Future<void> stageMaterialFileForUpload({
    required String materialId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  });
  Future<void> clearAllCache();
}

class LearningMaterialLocalDataSourceImpl implements LearningMaterialLocalDataSource {
  final LocalDatabase _localDatabase;
  final SyncQueue _syncQueue;

  LearningMaterialLocalDataSourceImpl(this._localDatabase, this._syncQueue);

  @override
  Future<List<LearningMaterialModel>> getCachedMaterials(String classId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'learning_materials',
        where: 'class_id = ?',
        whereArgs: [classId],
        orderBy: 'order_index ASC',
      );

      if (results.isEmpty) {
        throw CacheException('No cached materials for class $classId');
      }

      return results.map((r) => LearningMaterialModel.fromMap(r)).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<LearningMaterialModel> getCachedMaterialDetail(String materialId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'learning_materials',
        where: 'id = ?',
        whereArgs: [materialId],
      );

      if (results.isEmpty) {
        throw CacheException('Material $materialId not cached');
      }

      return LearningMaterialModel.fromMap(results.first);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheMaterials(List<LearningMaterialModel> materials) async {
    try {
      final db = await _localDatabase.database;
      await db.transaction((txn) async {
        for (final material in materials) {
          final map = material.toMap();
          map['cached_at'] = DateTime.now().toIso8601String();
          map['sync_status'] = 'synced';
          map['is_offline_mutation'] = 0;

          await txn.insert(
            'learning_materials',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache materials: $e');
    }
  }

  @override
  Future<void> cacheMaterialDetail(LearningMaterialModel material) async {
    try {
      final db = await _localDatabase.database;
      final map = material.toMap();
      map['cached_at'] = DateTime.now().toIso8601String();
      map['sync_status'] = 'synced';
      map['is_offline_mutation'] = 0;

      await db.insert(
        'learning_materials',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache material detail: $e');
    }
  }

  @override
  Future<void> cacheFile(String fileId, String fileName, List<int> bytes) async {
    try {
      final appDirDoc = await getApplicationDocumentsDirectory();
      final materialFilesDir = Directory('${appDirDoc.path}/material_files');

      if (!await materialFilesDir.exists()) {
        await materialFilesDir.create(recursive: true);
      }

      // Compress if file is > 5MB
      final (dataToWrite, wasCompressed) = CompressionUtil.compressIfNeeded(bytes);

      final filePath = '${materialFilesDir.path}/$fileId.cache';
      final file = File(filePath);
      await file.writeAsBytes(dataToWrite);

      // Update database with compression flag
      final db = await _localDatabase.database;
      await db.update(
        'material_files',
        {
          'local_path': filePath,
          'is_cached': 1,
          'is_compressed': wasCompressed ? 1 : 0,
          'cached_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [fileId],
      );
    } catch (e) {
      throw CacheException('Failed to cache file: $e');
    }
  }

  @override
  Future<List<int>> getCachedFile(String fileId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'material_files',
        where: 'id = ?',
        whereArgs: [fileId],
      );

      if (results.isEmpty || results.first['local_path'] == null) {
        throw CacheException('File $fileId not cached');
      }

      final filePath = results.first['local_path'] as String;
      final wasCompressed = (results.first['is_compressed'] as int?) == 1;
      final file = File(filePath);

      if (!await file.exists()) {
        throw CacheException('Cached file does not exist: $filePath');
      }

      final data = await file.readAsBytes();
      return CompressionUtil.decompressIfNeeded(data, wasCompressed);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to get cached file: $e');
    }
  }

  @override
  Future<bool> isFileCached(String fileId) async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query(
        'material_files',
        where: 'id = ? AND is_cached = 1',
        whereArgs: [fileId],
      );
      return results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<LearningMaterialModel> createMaterialLocally({
    required String classId,
    required String title,
    required String description,
    required String contentText,
  }) async {
    try {
      final db = await _localDatabase.database;
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
        // Insert material
        final map = material.toMap();
        map['cached_at'] = now.toIso8601String();
        map['sync_status'] = 'pending';
        map['is_offline_mutation'] = 1;

        await txn.insert('learning_materials', map);

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.learningMaterial,
            operation: SyncOperation.create,
            payload: {
              'local_id': id,
              'class_id': classId,
              'title': title,
              'description': description,
              'content_text': contentText,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
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
      final db = await _localDatabase.database;
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Update material
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

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
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
          ),
        );
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
      final db = await _localDatabase.database;
      final now = DateTime.now();
      final fileId = const Uuid().v4();
      final appDir = await getApplicationDocumentsDirectory();
      final uploadDir = Directory('${appDir.path}/offline_uploads');

      if (!await uploadDir.exists()) {
        await uploadDir.create(recursive: true);
      }

      // Copy file from temp location to offline_uploads
      final sourceFile = File(localPath);
      if (!await sourceFile.exists()) {
        throw CacheException('Source file does not exist: $localPath');
      }

      final stagedPath = '${uploadDir.path}/${fileId}_$fileName';
      await sourceFile.copy(stagedPath);

      // Insert file record
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

      // Enqueue sync
      await _syncQueue.enqueue(
        SyncQueueEntry(
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
        ),
      );
    } catch (e) {
      throw CacheException('Failed to stage material file for upload: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      final db = await _localDatabase.database;
      await db.delete('learning_materials');
      await db.delete('material_files');
    } catch (e) {
      throw CacheException('Failed to clear learning materials cache: $e');
    }
  }
}
