import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheStartSubmissionResultOp(
  LocalDatabase localDatabase,
  String submissionId,
  String assessmentId,
  String studentId,
  String studentName,
  String studentUsername,
  DateTime startedAt,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.insert(
      DbTables.assessmentSubmissions,
      {
        CommonCols.id: submissionId,
        AssessmentSubmissionsCols.assessmentId: assessmentId,
        AssessmentSubmissionsCols.userId: studentId,
        AssessmentSubmissionsCols.startedAt: startedAt.toIso8601String(),
        AssessmentSubmissionsCols.totalPoints: 0,
        CommonCols.createdAt: now.toIso8601String(),
        CommonCols.updatedAt: now.toIso8601String(),
        CommonCols.cachedAt: now.toIso8601String(),
        CommonCols.needsSync: 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    throw CacheException('Failed to cache start submission result: $e');
  }
}
