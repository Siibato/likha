import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:path_provider/path_provider.dart';

Future<List<int>> getCachedFileBytesOp(
  LocalDatabase localDatabase,
  String fileId,
) async {
  if (kIsWeb) throw CacheException('File caching not supported on web');
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.submissionFiles,
      where: '${CommonCols.id} = ?',
      whereArgs: [fileId],
    );

    if (results.isEmpty) {
      throw CacheException('File $fileId not found in database');
    }

    final fileName = results.first[SubmissionFilesCols.fileName] as String?;
    if (fileName == null || fileName.isEmpty) {
      throw CacheException('File $fileId has no fileName in database');
    }

    // Use expected path based on naming convention
    final expectedPath = await getExpectedFilePathOp(fileId, fileName);
    if (expectedPath == null) {
      throw CacheException('Could not construct expected path for file $fileId');
    }

    final file = File(expectedPath);

    if (!await file.exists()) {
      // Clean up DB entry
      await db.update(
        DbTables.submissionFiles,
        {SubmissionFilesCols.localPath: ''},
        where: '${CommonCols.id} = ?',
        whereArgs: [fileId],
      );
      throw CacheException('File not found at: $expectedPath');
    }

    return await file.readAsBytes();
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException('Failed to get cached file: $e');
  }
}

Future<String?> getExpectedFilePathOp(String fileId, String fileName) async {
  if (kIsWeb) return null;
  try {
    final appDirDoc = await getApplicationDocumentsDirectory();
    final submissionFilesDir = Directory('${appDirDoc.path}/submission_files');
    final shortId = fileId.substring(0, 8);
    final dotIndex = fileName.lastIndexOf('.');
    final localFileName = dotIndex > 0
        ? '${fileName.substring(0, dotIndex)}-$shortId${fileName.substring(dotIndex)}'
        : '$fileName-$shortId';
    final expectedPath = '${submissionFilesDir.path}/$localFileName';
    return expectedPath;
  } catch (e) {
    return null;
  }
}
