import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> isFileCachedOp(
  LocalDatabase localDatabase,
  String fileId,
) async {
  if (kIsWeb) return false;
  try {
    final db = await localDatabase.database;

    // Get file metadata from DB to find the expected filename
    final results = await db.query(
      DbTables.submissionFiles,
      where: '${CommonCols.id} = ?',
      whereArgs: [fileId],
    );

    if (results.isEmpty) {
      return false;
    }

    final fileName = results.first[SubmissionFilesCols.fileName] as String?;
    if (fileName == null || fileName.isEmpty) {
      return false;
    }

    // Construct expected path using naming convention: {nameWithoutExt}-{shortId}.{ext}
    final expectedPath = await getExpectedFilePathOp(fileId, fileName);
    if (expectedPath == null) {
      return false;
    }

    // Check if file actually exists at expected location
    final file = File(expectedPath);
    final exists = await file.exists();

    // If exists but DB path is empty/stale, update it for next time
    final storedPath = results.first['local_path'] as String?;
    if (exists && (storedPath == null || storedPath.isEmpty)) {
      await db.update(
        DbTables.submissionFiles,
        {SubmissionFilesCols.localPath: expectedPath},
        where: '${CommonCols.id} = ?',
        whereArgs: [fileId],
      );
    }

    return exists;
  } catch (e) {
    return false;
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
    return '${submissionFilesDir.path}/$localFileName';
  } catch (e) {
    return null;
  }
}
