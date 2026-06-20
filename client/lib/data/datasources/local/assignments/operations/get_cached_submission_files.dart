import 'dart:io';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'file_path_utils.dart';

Future<List<SubmissionFileModel>> getCachedSubmissionFiles(
  dynamic db,
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
        final expectedPath = await getExpectedFilePath(fileId, fileName);
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

