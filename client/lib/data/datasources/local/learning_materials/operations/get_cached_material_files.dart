import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';
import 'package:likha/core/database/db_schema.dart';

Future<List<MaterialFileModel>> getCachedMaterialFiles(
  LocalDatabase localDatabase,
  String materialId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.materialFiles,
      where: '${MaterialFilesCols.materialId} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [materialId],
      orderBy: '${MaterialFilesCols.uploadedAt} ASC',
    );

    // Log what we loaded from the database
    CacheLogger.instance.log('getCachedMaterialFiles for materialId: $materialId');
    CacheLogger.instance.log('Found ${results.length} file(s)');
    for (var i = 0; i < results.length; i++) {
      final row = results[i];
      CacheLogger.instance.log('File $i: ${row['file_name']} (id: ${row['id']}, local_path: ${row['local_path']})');
    }

    // Build models directly from DB rows (no filesystem I/O in the hot read path)
    return results.map((row) => MaterialFileModel.fromMap(row)).toList();
  } catch (e) {
    throw CacheException('Failed to fetch material files: $e');
  }
}

