import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:path_provider/path_provider.dart';

Future<void> cacheFile(
  LocalDatabase localDatabase,
  String fileId,
  String fileName,
  List<int> bytes,
) async {
  if (kIsWeb) return;
  try {
    CacheLogger.instance.log('Caching file $fileId (${bytes.length} bytes)');
    final appDirDoc = await getApplicationDocumentsDirectory();
    final materialFilesDir = Directory('${appDirDoc.path}/material_files');
    if (!await materialFilesDir.exists()) {
      CacheLogger.instance.log('Creating directory: ${materialFilesDir.path}');
      await materialFilesDir.create(recursive: true);
    }

    // Query material_files for the canonical file_name to ensure correct extension
    final db = await localDatabase.database;
    final rows = await db.query(
      'material_files',
      columns: ['file_name'],
      where: 'id = ?',
      whereArgs: [fileId],
    );
    final storedFileName = rows.isNotEmpty
        ? rows.first['file_name'] as String?
        : null;
    final finalFileName = storedFileName ?? fileName;

    // Apply naming convention: {nameWithoutExt}-{shortId}.{ext}
    final shortId = fileId.substring(0, 8);
    final dotIndex = finalFileName.lastIndexOf('.');
    final localFileName = dotIndex > 0
        ? '${finalFileName.substring(0, dotIndex)}-$shortId${finalFileName.substring(dotIndex)}'
        : '$finalFileName-$shortId';
    final filePath = '${materialFilesDir.path}/$localFileName';
    CacheLogger.instance.log('Writing to: $filePath');
    await File(filePath).writeAsBytes(bytes);
    CacheLogger.instance.log('File written successfully');

    CacheLogger.instance.log('Updating DB: local_path=$filePath');
    final rowsAffected = await db.update(
      'material_files',
      {
        'local_path': filePath,
        'cached_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [fileId],
    );
    CacheLogger.instance.log('DB updated, rowsAffected=$rowsAffected');

    if (rowsAffected == 0) {
      CacheLogger.instance.warn('Update affected 0 rows (file might not exist in DB)');
    }
  } catch (e) {
    CacheLogger.instance.error('Error caching file', e);
    throw CacheException('Failed to cache file: $e');
  }
}

