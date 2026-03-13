import 'package:flutter/foundation.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';
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
        print('[GET_CACHED_MATERIALS] materialId=$materialId, fileCount=$actualCount');

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
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('[DB_LOAD] getCachedMaterialFiles for materialId: $materialId');
      debugPrint('[DB_LOAD] Found ${results.length} file(s)');
      for (var i = 0; i < results.length; i++) {
        final row = results[i];
        debugPrint('[DB_LOAD] File $i: ${row['file_name']}');
        debugPrint('[DB_LOAD]   - id: ${row['id']}');
        debugPrint('[DB_LOAD]   - user_save_path: ${row['user_save_path']}');
        debugPrint('[DB_LOAD]   - local_path: ${row['local_path']}');
      }
      debugPrint('═══════════════════════════════════════════════════════════');

      return results.map((row) => MaterialFileModel.fromMap(row)).toList();
    } catch (e) {
      throw CacheException('Failed to fetch material files: $e');
    }
  }
}