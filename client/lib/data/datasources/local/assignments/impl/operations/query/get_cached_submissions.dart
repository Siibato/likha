import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';

Future<List<SubmissionListItemModel>> getCachedSubmissionsOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  String assignmentId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.rawQuery('''
      SELECT s.*, u.full_name as student_name, u.username as student_username
      FROM ${DbTables.assignmentSubmissions} s
      LEFT JOIN ${DbTables.users} u ON u.id = s.student_id
      WHERE s.assignment_id = ? AND s.deleted_at IS NULL
      ORDER BY CASE WHEN s.submitted_at IS NULL THEN 1 ELSE 0 END ASC, s.submitted_at ASC
    ''', [assignmentId]);
    if (results.isEmpty) return [];
    return results.map((row) {
      final d = _decryptSubmissionRow(enc, row);
      return SubmissionListItemModel(
        id: d['id'] as String,
        studentId: d['student_id'] as String,
        studentName: d['student_name'] as String? ?? '',
        studentUsername: d['student_username'] as String? ?? '',
        status: d['status'] as String,
        submittedAt: d['submitted_at'] != null ? DateTime.parse(d['submitted_at'] as String) : null,
        score: d['points'] as int?,
      );
    }).toList();
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}

Map<String, dynamic> _decryptSubmissionRow(EncryptionService enc, Map<String, dynamic> row) {
  final m = Map<String, dynamic>.from(row);
  m[AssignmentSubmissionsCols.textContent] = enc.decryptField(row[AssignmentSubmissionsCols.textContent] as String?);
  m[AssignmentSubmissionsCols.feedback] = enc.decryptField(row[AssignmentSubmissionsCols.feedback] as String?);
  if (m.containsKey('student_name')) m['student_name'] = enc.decryptField(row['student_name'] as String?);
  if (m.containsKey('student_username')) m['student_username'] = enc.decryptField(row['student_username'] as String?);
  return m;
}
