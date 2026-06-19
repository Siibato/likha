import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/core/database/db_schema.dart';

Future<List<LearningMaterialModel>> getCachedMaterials(
  LocalDatabase localDatabase,
  String classId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.learningMaterials,
      where: '${LearningMaterialsCols.classId} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [classId],
      orderBy: '${LearningMaterialsCols.orderIndex} ASC',
    );
    if (results.isEmpty) return [];

    final materials = <LearningMaterialModel>[];

    // Compute actual file count from the material_files table for each material
    for (final result in results) {
      final materialId = result['id'] as String;
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbTables.materialFiles} WHERE material_id = ? AND deleted_at IS NULL',
        [materialId],
      );
      final actualCount = countResult.first['count'] as int? ?? 0;
      CacheLogger.instance.log('materialId=$materialId, fileCount=$actualCount');

      materials.add(LearningMaterialModel(
        id: materialId,
        classId: result['class_id'] as String,
        title: result['title'] as String? ?? '',
        description: result['description'] as String?,
        contentText: result['content_text'] as String?,
        orderIndex: result['order_index'] as int,
        fileCount: actualCount,
        createdAt: DateTime.parse(result['created_at'] as String),
        updatedAt: DateTime.parse(result['updated_at'] as String),
        cachedAt: result['cached_at'] != null ? DateTime.parse(result['cached_at'] as String) : null,
        syncStatus: SyncStatus.values.firstWhere(
          (e) => e.dbValue == (result['sync_status'] as String?),
          orElse: () => SyncStatus.synced,
        ),
        deletedAt: result['deleted_at'] != null ? DateTime.parse(result['deleted_at'] as String) : null,
      ));
    }

    return materials;
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}
