import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheStartSubmissionResult(
  LocalDatabase localDatabase,
  String submissionId,
  String assessmentId,
  String studentId,
  String studentName,
  String studentUsername,
  DateTime startedAt, {
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now();
    final data = {
      CommonCols.id: submissionId,
      AssessmentSubmissionsCols.assessmentId: assessmentId,
      AssessmentSubmissionsCols.userId: studentId,
      AssessmentSubmissionsCols.startedAt: startedAt.toIso8601String(),
      AssessmentSubmissionsCols.totalPoints: 0,
      CommonCols.createdAt: now.toIso8601String(),
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.cachedAt: now.toIso8601String(),
      CommonCols.syncStatus: 'synced',
    };

    if (txn != null) {
      await txn.insert(DbTables.assessmentSubmissions, data, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      final db = await localDatabase.database;
      await db.insert(DbTables.assessmentSubmissions, data, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  } catch (e) {
    throw CacheException('Failed to cache start submission result: $e');
  }
}
