import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:path_provider/path_provider.dart';

Future<List<int>> getCachedFile(
  LocalDatabase localDatabase,
  String fileId,
) async {
  if (kIsWeb) throw CacheException('File caching not supported on web');
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      'material_files',
      where: 'id = ?',
      whereArgs: [fileId],
    );

    if (results.isEmpty) {
      throw CacheException('File $fileId not found in database');
    }

    final fileName = results.first['file_name'] as String?;
    if (fileName == null || fileName.isEmpty) {
      throw CacheException('File $fileId has no fileName in database');
    }

    // Use expected path based on naming convention
    final expectedPath = await _getExpectedFilePath(fileId, fileName);
    if (expectedPath == null) {
      throw CacheException('Could not construct expected path for file $fileId');
    }

    final file = File(expectedPath);

    if (!await file.exists()) {
      CacheLogger.instance.warn('File $fileId not found at expected path: $expectedPath');
      // Clean up DB entry
      await db.update(
        'material_files',
        {'local_path': ''},
        where: 'id = ?',
        whereArgs: [fileId],
      );
      throw CacheException('File not found at: $expectedPath');
    }

    CacheLogger.instance.log('Retrieved cached file: $fileId from $expectedPath');
    return await file.readAsBytes();
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException('Failed to get cached file: $e');
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
