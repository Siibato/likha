import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../learning_material_local_datasource_base.dart';

mixin LearningMaterialCacheMixin on LearningMaterialLocalDataSourceBase {
  @override
  Future<void> cacheMaterials(List<LearningMaterialModel> materials) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        for (final material in materials) {
          final map = material.toMap();
          map['cached_at'] = DateTime.now().toIso8601String();
          map['needs_sync'] = 0;
          // Manual UPSERT: UPDATE first, INSERT if rowsUpdated == 0
          final rowsUpdated = await txn.update(
            'learning_materials',
            map,
            where: 'id = ?',
            whereArgs: [map['id']],
          );
          if (rowsUpdated == 0) {
            await txn.insert(
              'learning_materials',
              map,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache materials: $e');
    }
  }

  @override
  Future<void> cacheMaterialDetail(LearningMaterialModel material) async {
    try {
      final db = await localDatabase.database;
      final map = material.toMap();
      map['cached_at'] = DateTime.now().toIso8601String();
      map['needs_sync'] = 0;
      // Manual UPSERT: UPDATE first, INSERT if rowsUpdated == 0
      final rowsUpdated = await db.update(
        'learning_materials',
        map,
        where: 'id = ?',
        whereArgs: [map['id']],
      );
      if (rowsUpdated == 0) {
        await db.insert(
          'learning_materials',
          map,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    } catch (e) {
      throw CacheException('Failed to cache material detail: $e');
    }
  }

  @override
  Future<void> cacheFile(String fileId, String fileName, List<int> bytes) async {
    if (kIsWeb) return;
    try {
      CacheLogger.instance.log('Caching file $fileId (${bytes.length} bytes)');
      final appDirDoc = await getApplicationDocumentsDirectory();
      final materialFilesDir = Directory('${appDirDoc.path}/material_files');
      if (!await materialFilesDir.exists()) {
        CacheLogger.instance.log('Creating directory: ${materialFilesDir.path}');
        await materialFilesDir.create(recursive: true);
      }

      // Query material_files for the canonical file_name to ensure correct extension
      final db = await localDatabase.database;
      final rows = await db.query(
        'material_files',
        columns: ['file_name'],
        where: 'id = ?',
        whereArgs: [fileId],
      );
      final storedFileName = rows.isNotEmpty
          ? rows.first['file_name'] as String?
          : null;
      final finalFileName = storedFileName ?? fileName;

      // Apply naming convention: {nameWithoutExt}-{shortId}.{ext}
      final shortId = fileId.substring(0, 8);
      final dotIndex = finalFileName.lastIndexOf('.');
      final localFileName = dotIndex > 0
          ? '${finalFileName.substring(0, dotIndex)}-$shortId${finalFileName.substring(dotIndex)}'
          : '$finalFileName-$shortId';
      final filePath = '${materialFilesDir.path}/$localFileName';
      CacheLogger.instance.log('Writing to: $filePath');
      await File(filePath).writeAsBytes(bytes);
      CacheLogger.instance.log('File written successfully');

      CacheLogger.instance.log('Updating DB: local_path=$filePath');
      final rowsAffected = await db.update(
        'material_files',
        {
          'local_path': filePath,
          'cached_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [fileId],
      );
      CacheLogger.instance.log('DB updated, rowsAffected=$rowsAffected');

      if (rowsAffected == 0) {
        CacheLogger.instance.warn('Update affected 0 rows (file might not exist in DB)');
      }
    } catch (e) {
      CacheLogger.instance.error('Error caching file', e);
      throw CacheException('Failed to cache file: $e');
    }
  }

  @override
  Future<List<int>> getCachedFile(String fileId) async {
    if (kIsWeb) throw CacheException('File caching not supported on web');
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'material_files',
        where: 'id = ?',
        whereArgs: [fileId],
      );

      if (results.isEmpty) {
        throw CacheException('File $fileId not found in database');
      }

      final fileName = results.first['file_name'] as String?;
      if (fileName == null || fileName.isEmpty) {
        throw CacheException('File $fileId has no fileName in database');
      }

      // Use expected path based on naming convention
      final expectedPath = await getExpectedFilePath(fileId, fileName);
      if (expectedPath == null) {
        throw CacheException('Could not construct expected path for file $fileId');
      }

      final file = File(expectedPath);

      if (!await file.exists()) {
        CacheLogger.instance.warn('File $fileId not found at expected path: $expectedPath');
        // Clean up DB entry
        await db.update(
          'material_files',
          {'local_path': ''},
          where: 'id = ?',
          whereArgs: [fileId],
        );
        throw CacheException('File not found at: $expectedPath');
      }

      CacheLogger.instance.log('Retrieved cached file: $fileId from $expectedPath');
      return await file.readAsBytes();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to get cached file: $e');
    }
  }

  /// Get expected file path based on fileId and fileName
  /// Uses naming convention: {nameWithoutExt}-{shortId}.{ext}
  /// Example: report.pdf with fileId cfa3d566-... → report-cfa3d566.pdf
  Future<String?> getExpectedFilePath(String fileId, String fileName) async {
    if (kIsWeb) return null;
    try {
      final appDirDoc = await getApplicationDocumentsDirectory();
      final materialFilesDir = Directory('${appDirDoc.path}/material_files');

      final shortId = fileId.substring(0, 8);
      final dotIndex = fileName.lastIndexOf('.');
      final localFileName = dotIndex > 0
          ? '${fileName.substring(0, dotIndex)}-$shortId${fileName.substring(dotIndex)}'
          : '$fileName-$shortId';
      final expectedPath = '${materialFilesDir.path}/$localFileName';
      return expectedPath;
    } catch (e) {
      CacheLogger.instance.error('Error getting expected path', e);
      return null;
    }
  }

  @override
  Future<bool> isFileCached(String fileId) async {
    if (kIsWeb) return false;
    try {
      final db = await localDatabase.database;

      // Get file metadata from DB to find the expected filename
      final results = await db.query(
        'material_files',
        where: 'id = ?',
        whereArgs: [fileId],
      );

      if (results.isEmpty) {
        CacheLogger.instance.warn('fileId=$fileId not found in DB');
        return false;
      }

      final fileName = results.first['file_name'] as String?;
      if (fileName == null || fileName.isEmpty) {
        CacheLogger.instance.warn('fileId=$fileId has no fileName');
        return false;
      }

      // Construct expected path using naming convention: {fileId}-{fileName}
      final expectedPath = await getExpectedFilePath(fileId, fileName);
      if (expectedPath == null) {
        return false;
      }

      // Check if file actually exists at expected location
      final file = File(expectedPath);
      final exists = await file.exists();
      CacheLogger.instance.log('fileId=$fileId, fileName=$fileName, expectedPath=$expectedPath, exists=$exists');

      // If exists but DB path is empty/stale, update it for next time
      final storedPath = results.first['local_path'] as String?;
      if (exists && (storedPath == null || storedPath.isEmpty)) {
        CacheLogger.instance.log('Updating DB with found path');
        await db.update(
          'material_files',
          {'local_path': expectedPath},
          where: 'id = ?',
          whereArgs: [fileId],
        );
      }

      return exists;
    } catch (e) {
      CacheLogger.instance.error('Error checking if file cached', e);
      return false;
    }
  }

  @override
  Future<void> cacheMaterialFiles(String materialId, List<MaterialFile> files) async {
    try {
      CacheLogger.instance.log('Starting cacheMaterialFiles with ${files.length} files for materialId=$materialId');
      final db = await localDatabase.database;
      for (final file in files) {
        // Preserve local cache state if row already exists
        final existing = await db.query(
          'material_files',
          columns: ['local_path'],
          where: 'id = ?',
          whereArgs: [file.id],
        );

        if (existing.isEmpty) {
          CacheLogger.instance.log('Inserting new file: ${file.fileName} (${file.id})');
          final rowsAffected = await db.insert(
            'material_files',
            {
              'id': file.id,
              'material_id': materialId,
              'file_name': file.fileName,
              'file_type': file.fileType,
              'file_size': file.fileSize,
              'uploaded_at': file.uploadedAt.toIso8601String(),
              'local_path': '',
              'cached_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          CacheLogger.instance.log('Insert completed, rowsAffected=$rowsAffected');
        } else {
          CacheLogger.instance.log('Updating existing file: ${file.fileName} (${file.id})');
          // Only update server-side metadata — preserve local_path
          final rowsAffected = await db.update(
            'material_files',
            {
              'file_name': file.fileName,
              'file_type': file.fileType,
              'file_size': file.fileSize,
              'uploaded_at': file.uploadedAt.toIso8601String(),
              'cached_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [file.id],
          );
          CacheLogger.instance.log('Update completed, rowsAffected=$rowsAffected');
        }
      }
      // Remove stale rows for this material that are no longer in the fresh list.
      // Use soft-delete when the server returns an empty list — an empty response may
      // indicate a fetch error rather than a genuine "no files" state, so a hard delete
      // here would be unrecoverable.
      if (files.isEmpty) {
        await db.update(
          'material_files',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'material_id = ? AND deleted_at IS NULL',
          whereArgs: [materialId],
        );
      } else {
        final freshIds = files.map((f) => f.id).toList();
        final placeholders = freshIds.map((_) => '?').join(', ');
        await db.rawDelete(
          'DELETE FROM material_files WHERE material_id = ? AND id NOT IN ($placeholders)',
          [materialId, ...freshIds],
        );
      }

      CacheLogger.instance.log('cacheMaterialFiles completed successfully');
    } catch (e) {
      CacheLogger.instance.error('Error in cacheMaterialFiles', e);
      throw CacheException('Failed to cache material files: $e');
    }
  }

  @override
  Future<void> reconcileDeletedMaterials(String classId, List<String> activeIds) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now().toIso8601String();

      if (activeIds.isEmpty) {
        // Soft-delete all active materials for this class
        await db.update(
          'learning_materials',
          {'deleted_at': now},
          where: 'class_id = ? AND deleted_at IS NULL',
          whereArgs: [classId],
        );
      } else {
        // Soft-delete materials not in activeIds
        final placeholders = activeIds.map((_) => '?').join(', ');
        await db.rawUpdate(
          'UPDATE learning_materials SET deleted_at = ? WHERE class_id = ? AND deleted_at IS NULL AND id NOT IN ($placeholders)',
          [now, classId, ...activeIds],
        );
      }
    } catch (e) {
      throw CacheException('Failed to reconcile deleted materials: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      final db = await localDatabase.database;
      await db.delete('learning_materials');
      await db.delete('material_files');
    } catch (e) {
      throw CacheException('Failed to clear learning materials cache: $e');
    }
  }
}