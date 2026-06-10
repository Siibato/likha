import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'get_cached_submission_files.dart';

Future<AssignmentSubmissionModel?> getCachedSubmissionOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  String submissionId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.rawQuery('''
      SELECT s.*, u.full_name as student_name
      FROM ${DbTables.assignmentSubmissions} s
      LEFT JOIN ${DbTables.users} u ON u.id = s.student_id
      WHERE s.id = ?
    ''', [submissionId]);
    if (results.isEmpty) return null;

    // NEW: Query files from submission_files table
    final files = await getCachedSubmissionFilesOp(db, enc, submissionId);

    final decryptedSub = _decryptSubmissionRow(enc, results.first);
    return AssignmentSubmissionModel(
      id: decryptedSub['id'] as String,
      assignmentId: decryptedSub['assignment_id'] as String,
      studentId: decryptedSub['student_id'] as String,
      studentName: decryptedSub['student_name'] as String? ?? '',
      status: decryptedSub['status'] as String,
      textContent: decryptedSub['text_content'] as String?,
      submittedAt: decryptedSub['submitted_at'] != null ? DateTime.parse(decryptedSub['submitted_at'] as String) : null,
      score: decryptedSub['points'] as int?,
      feedback: decryptedSub['feedback'] as String?,
      gradedAt: decryptedSub['graded_at'] != null ? DateTime.parse(decryptedSub['graded_at'] as String) : null,
      gradedBy: decryptedSub['graded_by'] as String?,
      files: files,
      createdAt: DateTime.parse(decryptedSub['created_at'] as String),
      updatedAt: DateTime.parse(decryptedSub['updated_at'] as String),
    );
  } catch (e) {
    throw CacheException('Failed to get cached submission: $e');
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
