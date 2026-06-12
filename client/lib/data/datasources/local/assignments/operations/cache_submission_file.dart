import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheSubmissionFile(
  LocalDatabase localDatabase,
  String submissionId,
  SubmissionFileModel file,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now().toIso8601String();
    final existing = await db.query(
      DbTables.submissionFiles,
      where: '${CommonCols.id} = ?',
      whereArgs: [file.id],
    );
    if (existing.isEmpty) {
      await db.insert(DbTables.submissionFiles, {
        CommonCols.id: file.id,
        SubmissionFilesCols.submissionId: submissionId,
        SubmissionFilesCols.fileName: file.fileName,
        SubmissionFilesCols.fileType: file.fileType,
        SubmissionFilesCols.fileSize: file.fileSize,
        SubmissionFilesCols.uploadedAt: file.uploadedAt.toIso8601String(),
        SubmissionFilesCols.localPath: '',
        CommonCols.cachedAt: now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  } catch (e) {
    throw CacheException('Failed to cache submission file: $e');
  }
}
