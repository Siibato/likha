import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:path_provider/path_provider.dart';

Future<List<SubmissionFileModel>> getCachedSubmissionFilesOp(
  dynamic db,
  EncryptionService enc,
  String submissionId,
) async {
  try {
    final results = await db.query(
      DbTables.submissionFiles,
      where: '${SubmissionFilesCols.submissionId} = ?',
      whereArgs: [submissionId],
      orderBy: '${SubmissionFilesCols.uploadedAt} ASC',
    );

    final models = <SubmissionFileModel>[];
    for (final row in results) {
      final fileId = row['id'] as String;
      final fileName = row['file_name'] as String?;
      var localPath = row['local_path'] as String?;

      // Auto-repair: if local_path is empty but file exists on disk, restore it
      if ((localPath == null || localPath.isEmpty) && fileName != null) {
        final expectedPath = await getExpectedFilePathOp(fileId, fileName);
        if (expectedPath != null) {
          final file = File(expectedPath);
          if (await file.exists()) {
            await db.update(
              DbTables.submissionFiles,
              {SubmissionFilesCols.localPath: expectedPath},
              where: '${CommonCols.id} = ?',
              whereArgs: [fileId],
            );
            localPath = expectedPath;
          }
        }
      }

      final updatedRow = Map<String, dynamic>.from(row);
      updatedRow['local_path'] = localPath;
      models.add(SubmissionFileModel.fromMap(updatedRow));
    }
    return models;
  } catch (e) {
    throw CacheException('Failed to fetch submission files: $e');
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
