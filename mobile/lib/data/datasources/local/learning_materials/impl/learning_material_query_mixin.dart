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
      if (results.isEmpty) throw CacheException('No cached materials for class $classId');
      return results.map((r) => LearningMaterialModel.fromMap(r)).toList();
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
      return LearningMaterialModel.fromMap(results.first);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  /// NEW: Get cached material files from SQLite
  @override
  Future<List<MaterialFileModel>> getCachedMaterialFiles(String materialId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'material_files',
        where: 'material_id = ? AND deleted_at IS NULL',
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
        debugPrint('[DB_LOAD]   - is_cached: ${row['is_cached']}');
        debugPrint('[DB_LOAD]   - local_path: ${row['local_path']}');
      }
      debugPrint('═══════════════════════════════════════════════════════════');

      return results.map((row) => MaterialFileModel.fromMap(row)).toList();
    } catch (e) {
      throw CacheException('Failed to fetch material files: $e');
    }
  }
}