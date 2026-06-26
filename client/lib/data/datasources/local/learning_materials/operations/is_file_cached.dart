import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> isFileCached(
  LocalDatabase localDatabase,
  String fileId,
) async {
  if (kIsWeb) return false;
  try {
    final db = await localDatabase.database;

    // Get file metadata from DB to find the expected filename
    final results = await db.query(
      'material_files',
      where: 'id = ?',
      whereArgs: [fileId],
    );

    if (results.isEmpty) {
      CacheLogger.instance.warn('fileId=$fileId not found in DB');
      return false;
    }

    final fileName = results.first['file_name'] as String?;
    if (fileName == null || fileName.isEmpty) {
      CacheLogger.instance.warn('fileId=$fileId has no fileName');
      return false;
    }

    // Construct expected path using naming convention: {fileId}-{fileName}
    final expectedPath = await _getExpectedFilePath(fileId, fileName);
    if (expectedPath == null) {
      return false;
    }

    // Check if file actually exists at expected location
    final file = File(expectedPath);
    final exists = await file.exists();
    CacheLogger.instance.log('fileId=$fileId, fileName=$fileName, expectedPath=$expectedPath, exists=$exists');

    // If exists but DB path is empty/stale, update it for next time
    final storedPath = results.first['local_path'] as String?;
    if (exists && (storedPath == null || storedPath.isEmpty)) {
      CacheLogger.instance.log('Updating DB with found path');
      await db.update(
        'material_files',
        {'local_path': expectedPath},
        where: 'id = ?',
        whereArgs: [fileId],
      );
    }

    // If file doesn't exist but DB has a local_path, clear it so UI reflects reality
    if (!exists && storedPath != null && storedPath.isNotEmpty) {
      CacheLogger.instance.log('File missing on disk, clearing stale local_path');
      await db.update(
        'material_files',
        {'local_path': '', 'cached_at': null},
        where: 'id = ?',
        whereArgs: [fileId],
      );
    }

    return exists;
  } catch (e) {
    CacheLogger.instance.error('Error checking if file cached', e);
    return false;
  }
}

/// Get expected file path based on fileId and fileName
/// Uses naming convention: {nameWithoutExt}-{shortId}.{ext}
/// Example: report.pdf with fileId cfa3d566-... → report-cfa3d566.pdf
Future<String?> _getExpectedFilePath(String fileId, String fileName) async {
  if (kIsWeb) return null;
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
    CacheLogger.instance.error('Error getting expected path', e);
    return null;
  }
}
