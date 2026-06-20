import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:path_provider/path_provider.dart';

Future<void> cacheFileBytes(
  LocalDatabase localDatabase,
  String fileId,
  String fileName,
  List<int> bytes,
) async {
  if (kIsWeb) return;
  try {
    final appDirDoc = await getApplicationDocumentsDirectory();
    final submissionFilesDir = Directory('${appDirDoc.path}/submission_files');
    if (!await submissionFilesDir.exists()) {
      await submissionFilesDir.create(recursive: true);
    }

    // Query submission_files for the canonical file_name to ensure correct extension
    final db = await localDatabase.database;
    final rows = await db.query(
      DbTables.submissionFiles,
      columns: [SubmissionFilesCols.fileName],
      where: '${CommonCols.id} = ?',
      whereArgs: [fileId],
    );
    final storedFileName = rows.isNotEmpty
        ? rows.first[SubmissionFilesCols.fileName] as String?
        : null;
    final finalFileName = storedFileName ?? fileName;

    // Apply naming convention: {nameWithoutExt}-{shortId}.{ext}
    final shortId = fileId.substring(0, 8);
    final dotIndex = finalFileName.lastIndexOf('.');
    final localFileName = dotIndex > 0
        ? '${finalFileName.substring(0, dotIndex)}-$shortId${finalFileName.substring(dotIndex)}'
        : '$finalFileName-$shortId';
    final filePath = '${submissionFilesDir.path}/$localFileName';

    await File(filePath).writeAsBytes(bytes);

    // Update DB with the cached file path
    await db.update(
      DbTables.submissionFiles,
      {
        SubmissionFilesCols.localPath: filePath,
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [fileId],
    );
  } catch (e) {
    throw CacheException('Failed to cache file: $e');
  }
}
