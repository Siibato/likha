import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheStudentSubmission(
  LocalDatabase localDatabase,
  String assessmentId,
  String studentId,
  SubmissionSummaryModel? submission,
) async {
  try {
    final db = await localDatabase.database;

    // First delete any existing cached submission for this assessment + student
    await db.delete(
      DbTables.assessmentSubmissions,
      where: '${AssessmentSubmissionsCols.assessmentId} = ? AND ${AssessmentSubmissionsCols.userId} = ?',
      whereArgs: [assessmentId, studentId],
    );

    if (submission == null) return;

    await db.insert(
      DbTables.assessmentSubmissions,
      {
        CommonCols.id: submission.id,
        AssessmentSubmissionsCols.assessmentId: assessmentId,
        AssessmentSubmissionsCols.userId: studentId,
        AssessmentSubmissionsCols.startedAt: submission.startedAt.toIso8601String(),
        AssessmentSubmissionsCols.submittedAt: submission.submittedAt?.toIso8601String(),
        AssessmentSubmissionsCols.totalPoints: submission.totalPoints,
        AssessmentSubmissionsCols.earnedPoints: submission.finalScore,
        CommonCols.createdAt: submission.createdAt?.toIso8601String(),
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
        CommonCols.syncStatus: 'synced',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    throw CacheException('Failed to cache student submission: $e');
  }
}
