import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheSubmissionFile(
  LocalDatabase localDatabase,
  String submissionId,
  SubmissionFileModel file, {
  Transaction? txn,
}) async {
  try {
    final db = await localDatabase.database;
    final executor = txn ?? db;
    final now = DateTime.now().toIso8601String();
    final existing = await executor.query(
      DbTables.submissionFiles,
      where: '${CommonCols.id} = ?',
      whereArgs: [file.id],
    );
    if (existing.isEmpty) {
      await executor.insert(DbTables.submissionFiles, {
        CommonCols.id: file.id,
        SubmissionFilesCols.submissionId: submissionId,
        SubmissionFilesCols.fileName: file.fileName,
        SubmissionFilesCols.fileType: file.fileType,
        SubmissionFilesCols.fileSize: file.fileSize,
        SubmissionFilesCols.uploadedAt: file.uploadedAt.toIso8601String(),
        SubmissionFilesCols.localPath: file.localPath ?? '',
        CommonCols.cachedAt: now,
        CommonCols.syncStatus: file.syncStatus.dbValue,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  } catch (e) {
    throw CacheException('Failed to cache submission file: $e');
  }
}
