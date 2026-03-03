import 'dart:io';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/utils/compression_util.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
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
      final db = await localDatabase.database;
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

      final (dataToWrite, wasCompressed) = CompressionUtil.compressIfNeeded(bytes);
      final filePath = '${materialFilesDir.path}/$fileId.cache';
      await File(filePath).writeAsBytes(dataToWrite);

      final db = await localDatabase.database;
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
      final db = await localDatabase.database;
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