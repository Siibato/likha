import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

Future<String> startAssessment(
  LocalDatabase localDatabase,
  String assessmentId,
  String studentId,
  String studentName,
  String studentUsername, {
  Transaction? txn,
}) async {
  try {
    final localId = const Uuid().v4();
    final now = DateTime.now();
    final data = {
      CommonCols.id: localId,
      AssessmentSubmissionsCols.assessmentId: assessmentId,
      AssessmentSubmissionsCols.userId: studentId,
      AssessmentSubmissionsCols.startedAt: now.toIso8601String(),
      AssessmentSubmissionsCols.totalPoints: 0,
      CommonCols.createdAt: now.toIso8601String(),
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.cachedAt: now.toIso8601String(),
      CommonCols.syncStatus: 'pending',
    };

    if (txn != null) {
      await txn.insert(DbTables.assessmentSubmissions, data);
    } else {
      final db = await localDatabase.database;
      await db.insert(DbTables.assessmentSubmissions, data);
    }
    return localId;
  } catch (e) {
    throw CacheException('Failed to start assessment locally: $e');
  }
}
