import 'dart:io';
import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';
import 'package:path_provider/path_provider.dart';
import '../learning_material_local_datasource_base.dart';

mixin LearningMaterialQueryMixin on LearningMaterialLocalDataSourceBase {
  @override
  Future<List<LearningMaterialModel>> getCachedMaterials(String classId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'learning_materials',
        where: 'class_id = ? AND deleted_at IS NULL',
        whereArgs: [classId],
        orderBy: 'order_index ASC',
      );
      if (results.isEmpty) return [];

      final materials = <LearningMaterialModel>[];

      // Compute actual file count from the material_files table for each material
      for (final result in results) {
        final materialId = result['id'] as String;
        final countResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM material_files WHERE material_id = ?',
          [materialId],
        );
        final actualCount = countResult.first['count'] as int? ?? 0;
        CacheLogger.instance.log('materialId=$materialId, fileCount=$actualCount');

        materials.add(LearningMaterialModel(
          id: materialId,
          classId: result['class_id'] as String,
          title: result['title'] as String,
          description: result['description'] as String?,
          contentText: result['content_text'] as String?,
          orderIndex: result['order_index'] as int,
          fileCount: actualCount,
          createdAt: DateTime.parse(result['created_at'] as String),
          updatedAt: DateTime.parse(result['updated_at'] as String),
          cachedAt: result['cached_at'] != null ? DateTime.parse(result['cached_at'] as String) : null,
          needsSync: (result['needs_sync'] as int?) == 1,
          deletedAt: result['deleted_at'] != null ? DateTime.parse(result['deleted_at'] as String) : null,
        ));
      }

      return materials;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<LearningMaterialModel> getCachedMaterialDetail(String materialId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'learning_materials',
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [materialId],
      );

      if (results.isEmpty) throw CacheException('Material $materialId not cached');

      final r = results.first;

      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM material_files WHERE material_id = ?',
        [materialId],
      );
      final actualCount = countResult.first['count'] as int? ?? 0;

      return LearningMaterialModel(
        id: r['id'] as String,
        classId: r['class_id'] as String,
        title: r['title'] as String,
        description: r['description'] as String?,
        contentText: r['content_text'] as String?,
        orderIndex: r['order_index'] as int,
        fileCount: actualCount,
        createdAt: DateTime.parse(r['created_at'] as String),
        updatedAt: DateTime.parse(r['updated_at'] as String),
        cachedAt: r['cached_at'] != null ? DateTime.parse(r['cached_at'] as String) : null,
        needsSync: (r['needs_sync'] as int?) == 1,
        deletedAt: r['deleted_at'] != null ? DateTime.parse(r['deleted_at'] as String) : null,
      );
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<List<MaterialFileModel>> getCachedMaterialFiles(String materialId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'material_files',
        where: 'material_id = ?',
        whereArgs: [materialId],
        orderBy: 'uploaded_at ASC',
      );

      // Log what we loaded from the database
      CacheLogger.instance.log('getCachedMaterialFiles for materialId: $materialId');
      CacheLogger.instance.log('Found ${results.length} file(s)');
      for (var i = 0; i < results.length; i++) {
        final row = results[i];
        CacheLogger.instance.log('File $i: ${row['file_name']} (id: ${row['id']}, local_path: ${row['local_path']})');
      }

      // Build models with filesystem fallback + auto-repair
      final models = <MaterialFileModel>[];
      for (final row in results) {
        final fileId = row['id'] as String;
        final fileName = row['file_name'] as String?;
        var localPath = row['local_path'] as String?;

        // If local_path is empty but file exists on disk, restore it
        if ((localPath == null || localPath.isEmpty) && fileName != null) {
          final expectedPath = await _getExpectedFilePathForQuery(fileId, fileName);
          if (expectedPath != null) {
            final file = File(expectedPath);
            if (await file.exists()) {
              CacheLogger.instance.log('Found file on disk for $fileId, restoring DB path');
              // Update DB with the found path
              await db.update(
                'material_files',
                {'local_path': expectedPath},
                where: 'id = ?',
                whereArgs: [fileId],
              );
              localPath = expectedPath;
            }
          }
        }

        // Build the model with potentially restored local_path
        final updatedRow = Map<String, dynamic>.from(row);
        updatedRow['local_path'] = localPath;
        models.add(MaterialFileModel.fromMap(updatedRow));
      }

      return models;
    } catch (e) {
      throw CacheException('Failed to fetch material files: $e');
    }
  }

  /// Helper to compute expected file path using the short-ID naming convention
  /// Format: {nameWithoutExt}-{shortId}.{ext}
  Future<String?> _getExpectedFilePathForQuery(String fileId, String fileName) async {
    try {
      final appDirDoc = await getApplicationDocumentsDirectory();
      final materialFilesDir = Directory('${appDirDoc.path}/material_files');

      final shortId = fileId.substring(0, 8);
      final dotIndex = fileName.lastIndexOf('.');
      final localFileName = dotIndex > 0
          ? '${fileName.substring(0, dotIndex)}-$shortId${fileName.substring(dotIndex)}'
          : '$fileName-$shortId';
      return '${materialFilesDir.path}/$localFileName';
    } catch (e) {
      CacheLogger.instance.error('Error getting expected path', e);
      return null;
    }
  }
}