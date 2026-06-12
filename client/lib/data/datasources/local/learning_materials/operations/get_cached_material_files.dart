import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:path_provider/path_provider.dart';

Future<List<MaterialFileModel>> getCachedMaterialFiles(
  LocalDatabase localDatabase,
  String materialId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.materialFiles,
      where: '${MaterialFilesCols.materialId} = ?',
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
              DbTables.materialFiles,
              {MaterialFilesCols.localPath: expectedPath},
              where: '${CommonCols.id} = ?',
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
  if (kIsWeb) return null;
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
