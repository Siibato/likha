import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'get_cached_submission_files.dart';

Future<AssignmentSubmissionModel?> getCachedSubmission(
  LocalDatabase localDatabase,
  String submissionId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.rawQuery('''
      SELECT s.*, u.first_name || ' ' || u.last_name as student_name
      FROM ${DbTables.assignmentSubmissions} s
      LEFT JOIN ${DbTables.users} u ON u.id = s.student_id
      WHERE s.id = ?
    ''', [submissionId]);
    if (results.isEmpty) return null;

    // NEW: Query files from submission_files table
    final files = await getCachedSubmissionFiles(db, submissionId);

    final row = results.first;
    return AssignmentSubmissionModel(
      id: row['id'] as String,
      assignmentId: row['assignment_id'] as String,
      studentId: row['student_id'] as String,
      studentName: row['student_name'] as String? ?? '',
      status: row['status'] as String,
      textContent: row['text_content'] as String?,
      submittedAt: row['submitted_at'] != null ? DateTime.parse(row['submitted_at'] as String) : null,
      score: row['points'] as int?,
      feedback: row['feedback'] as String?,
      gradedAt: row['graded_at'] != null ? DateTime.parse(row['graded_at'] as String) : null,
      gradedBy: row['graded_by'] as String?,
      files: files,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  } catch (e) {
    throw CacheException('Failed to get cached submission: $e');
  }
}

