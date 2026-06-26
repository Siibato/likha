import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';

Future<List<SubmissionListItemModel>> getCachedSubmissions(
  LocalDatabase localDatabase,
  String assignmentId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.rawQuery('''
      SELECT s.*, u.first_name || ' ' || u.last_name as student_name, u.username as student_username
      FROM ${DbTables.assignmentSubmissions} s
      LEFT JOIN ${DbTables.users} u ON u.id = s.student_id
      WHERE s.assignment_id = ? AND s.deleted_at IS NULL
      ORDER BY u.last_name ASC, u.first_name ASC
    ''', [assignmentId]);
    if (results.isEmpty) return [];
    return results.map((row) {
      return SubmissionListItemModel(
        id: row['id'] as String,
        studentId: row['student_id'] as String,
        studentName: row['student_name'] as String? ?? '',
        studentUsername: row['student_username'] as String? ?? '',
        status: row['status'] as String,
        submittedAt: row['submitted_at'] != null ? DateTime.parse(row['submitted_at'] as String) : null,
        score: row['points'] as int?,
      );
    }).toList();
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}
