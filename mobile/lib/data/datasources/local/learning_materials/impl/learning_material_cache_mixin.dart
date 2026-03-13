import 'dart:io';
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
    try {
      print('[CACHE_FILE] 💾 Caching file $fileId (${bytes.length} bytes)');
      final appDirDoc = await getApplicationDocumentsDirectory();
      final materialFilesDir = Directory('${appDirDoc.path}/material_files');
      if (!await materialFilesDir.exists()) {
        print('[CACHE_FILE] 📁 Creating directory: ${materialFilesDir.path}');
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
      print('[CACHE_FILE] 📝 Writing to: $filePath');
      await File(filePath).writeAsBytes(bytes);
      print('[CACHE_FILE] ✅ File written successfully');

      print('[CACHE_FILE] 🔄 Updating DB: local_path=$filePath');
      final rowsAffected = await db.update(
        'material_files',
        {
          'local_path': filePath,
          'cached_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [fileId],
      );
      print('[CACHE_FILE] ✅ DB updated, rowsAffected=$rowsAffected');

      if (rowsAffected == 0) {
        print('[CACHE_FILE] ⚠️  WARNING: Update affected 0 rows (file might not exist in DB)');
      }
    } catch (e) {
      print('[CACHE_FILE] ❌ Error: $e');
      throw CacheException('Failed to cache file: $e');
    }
  }

  @override
  Future<List<int>> getCachedFile(String fileId) async {
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
        print('[GET_CACHED] ⚠️  File $fileId not found at expected path: $expectedPath');
        // Clean up DB entry
        await db.update(
          'material_files',
          {'local_path': ''},
          where: 'id = ?',
          whereArgs: [fileId],
        );
        throw CacheException('File not found at: $expectedPath');
      }

      print('[GET_CACHED] ✅ Retrieved cached file: $fileId from $expectedPath');
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
      print('[GET_EXPECTED_PATH] Error: $e');
      return null;
    }
  }

  @override
  Future<bool> isFileCached(String fileId) async {
    try {
      final db = await localDatabase.database;

      // Get file metadata from DB to find the expected filename
      final results = await db.query(
        'material_files',
        where: 'id = ?',
        whereArgs: [fileId],
      );

      if (results.isEmpty) {
        print('[IS_CACHED] ❌ fileId=$fileId not found in DB');
        return false;
      }

      final fileName = results.first['file_name'] as String?;
      if (fileName == null || fileName.isEmpty) {
        print('[IS_CACHED] ❌ fileId=$fileId has no fileName');
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
      print('[IS_CACHED] fileId=$fileId, fileName=$fileName, expectedPath=$expectedPath, exists=$exists');

      // If exists but DB path is empty/stale, update it for next time
      final storedPath = results.first['local_path'] as String?;
      if (exists && (storedPath == null || storedPath.isEmpty)) {
        print('[IS_CACHED] 🔄 Updating DB with found path');
        await db.update(
          'material_files',
          {'local_path': expectedPath},
          where: 'id = ?',
          whereArgs: [fileId],
        );
      }

      return exists;
    } catch (e) {
      print('[IS_CACHED] ❌ Error: $e');
      return false;
    }
  }

  @override
  Future<void> cacheMaterialFiles(String materialId, List<MaterialFile> files) async {
    try {
      print('[CACHE_FILES] 💾 Starting cacheMaterialFiles with ${files.length} files for materialId=$materialId');
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
          print('[CACHE_FILES] ➕ Inserting new file: ${file.fileName} (${file.id})');
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
          print('[CACHE_FILES] ✅ Insert completed, rowsAffected=$rowsAffected');
        } else {
          print('[CACHE_FILES] 🔄 Updating existing file: ${file.fileName} (${file.id})');
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
          print('[CACHE_FILES] ✅ Update completed, rowsAffected=$rowsAffected');
        }
      }
      print('[CACHE_FILES] ✅ cacheMaterialFiles completed successfully');
    } catch (e) {
      print('[CACHE_FILES] ❌ Error in cacheMaterialFiles: $e');
      throw CacheException('Failed to cache material files: $e');
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