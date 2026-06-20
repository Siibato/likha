import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'file_path_utils.dart';

Future<List<int>> getCachedFileBytes(
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
    final expectedPath = await getExpectedFilePath(fileId, fileName);
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

