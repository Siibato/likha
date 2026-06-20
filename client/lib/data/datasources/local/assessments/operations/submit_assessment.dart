import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> submitAssessment(
  LocalDatabase localDatabase,
  String submissionId,
  String assessmentId, {
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now();
    final data = {
      AssessmentSubmissionsCols.submittedAt: now.toIso8601String(),
      CommonCols.syncStatus: 'pending',
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.cachedAt: now.toIso8601String(),
    };
    const where = '${CommonCols.id} = ?';
    final whereArgs = [submissionId];

    if (txn != null) {
      await txn.update(DbTables.assessmentSubmissions, data, where: where, whereArgs: whereArgs);
    } else {
      final db = await localDatabase.database;
      await db.update(DbTables.assessmentSubmissions, data, where: where, whereArgs: whereArgs);
    }
  } catch (e) {
    throw CacheException('Failed to submit assessment locally: $e');
  }
}
