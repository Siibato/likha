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
      final db = await localDatabase.database;
      final map = material.toMap();
      map['cached_at'] = DateTime.now().toIso8601String();
      map['needs_sync'] = 0;
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

      // Store with fileId prefix and original filename to preserve extension
      final filePath = '${materialFilesDir.path}/$fileId-$finalFileName';
      await File(filePath).writeAsBytes(bytes);

      await db.update(
        'material_files',
        {
          'local_path': filePath,
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
      final db = await localDatabase.database;
      final results = await db.query(
        'material_files',
        where: 'id = ?',
        whereArgs: [fileId],
      );
      if (results.isEmpty || results.first['local_path'] == null) {
        throw CacheException('File $fileId not cached');
      }

      final filePath = results.first['local_path'] as String;
      final file = File(filePath);

      if (!await file.exists()) {
        throw CacheException('Cached file does not exist: $filePath');
      }

      return await file.readAsBytes();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to get cached file: $e');
    }
  }

  @override
  Future<bool> isFileCached(String fileId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'material_files',
        where: 'id = ? AND local_path IS NOT NULL AND local_path != ""',
        whereArgs: [fileId],
      );
      return results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> cacheMaterialFiles(String materialId, List<MaterialFile> files) async {
    try {
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
          await db.insert(
            'material_files',
            {
              'id': file.id,
              'material_id': materialId,
              'file_name': file.fileName,
              'file_type': file.fileType,
              'file_size': file.fileSize,
              'uploaded_at': file.uploadedAt.toIso8601String(),
              'local_path': null,
              'cached_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        } else {
          // Only update server-side metadata — preserve local_path
          await db.update(
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
        }
      }
    } catch (e) {
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