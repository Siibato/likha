import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<List<SubmissionSummaryModel>> getCachedSubmissions(
  LocalDatabase localDatabase,
  String assessmentId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.rawQuery('''
      SELECT s.*, u.first_name || ' ' || u.last_name as student_name, u.username as student_username
      FROM assessment_submissions s
      LEFT JOIN users u ON u.id = s.user_id
      WHERE s.assessment_id = ? AND s.deleted_at IS NULL
      ORDER BY u.last_name ASC, u.first_name ASC
    ''', [assessmentId]);

    if (results.isEmpty) return [];

    return results.map((row) => SubmissionSummaryModel(
      id: row['id'] as String,
      assessmentId: row['assessment_id'] as String? ?? '',
      studentId: row['user_id'] as String? ?? '',
      studentName: row['student_name'] as String? ?? '',
      studentUsername: row['student_username'] as String? ?? '',
      startedAt: DateTime.parse(row['started_at'] as String),
      submittedAt: row['submitted_at'] != null ? DateTime.parse(row['submitted_at'] as String) : null,
      autoScore: (row['earned_points'] as num?)?.toDouble() ?? 0.0,
      finalScore: (row['earned_points'] as num?)?.toDouble() ?? 0.0,
      totalPoints: (row['total_points'] as num?)?.toDouble() ?? 0.0,
      isSubmitted: row['submitted_at'] != null,
    )).toList();
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}
