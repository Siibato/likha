import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<SubmissionSummaryModel?> getCachedStudentSubmissionOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  String assessmentId,
  String studentId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.rawQuery('''
      SELECT s.*, u.full_name as student_name, u.username as student_username
      FROM ${DbTables.assessmentSubmissions} s
      LEFT JOIN ${DbTables.users} u ON u.id = s.user_id
      WHERE s.assessment_id = ? AND s.user_id = ? AND s.deleted_at IS NULL
      ORDER BY s.started_at DESC LIMIT 1
    ''', [assessmentId, studentId]);

    if (results.isEmpty) {
      return null;
    }

    final rawRow = results.first;
    return SubmissionSummaryModel(
      id: rawRow['id'] as String,
      assessmentId: rawRow['assessment_id'] as String? ?? '',
      studentId: rawRow['user_id'] as String? ?? '',
      studentName: enc.decryptField(rawRow['student_name'] as String?) ?? '',
      studentUsername: enc.decryptField(rawRow['student_username'] as String?) ?? '',
      startedAt: DateTime.parse(rawRow['started_at'] as String),
      submittedAt: rawRow['submitted_at'] != null ? DateTime.parse(rawRow['submitted_at'] as String) : null,
      autoScore: (rawRow['earned_points'] as num?)?.toDouble() ?? 0.0,
      finalScore: (rawRow['earned_points'] as num?)?.toDouble() ?? 0.0,
      totalPoints: (rawRow['total_points'] as num?)?.toDouble() ?? 0.0,
      isSubmitted: rawRow['submitted_at'] != null,
    );
  } catch (e) {
    throw CacheException('Failed to get student submission: $e');
  }
}
