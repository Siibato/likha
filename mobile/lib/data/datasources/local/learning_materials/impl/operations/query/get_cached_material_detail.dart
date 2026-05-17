import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/core/database/db_schema.dart';

Future<LearningMaterialModel> getCachedMaterialDetailOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  String materialId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.learningMaterials,
      where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
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
      title: enc.decryptField(r['title'] as String?) ?? '',
      description: r['description'] as String?,
      contentText: enc.decryptField(r['content_text'] as String?),
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
