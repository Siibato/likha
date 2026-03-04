import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart'
    show AssignmentSubmissionModel, SubmissionListItemModel;
import 'package:likha/data/models/assignments/submission_file_model.dart';
import '../assignment_local_datasource_base.dart';

mixin AssignmentQueryMixin on AssignmentLocalDataSourceBase {
  @override
  Future<List<AssignmentModel>> getCachedAssignments(String classId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'assignments',
        where: 'class_id = ? AND deleted_at IS NULL',
        whereArgs: [classId],
        orderBy: 'created_at DESC',
      );
      if (results.isEmpty) throw CacheException('No cached assignments for class $classId');
      return results.map(AssignmentModel.fromMap).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<AssignmentModel> getCachedAssignmentDetail(String assignmentId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'assignments',
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [assignmentId],
      );
      if (results.isEmpty) throw CacheException('Assignment $assignmentId not cached');
      return AssignmentModel.fromMap(results.first);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<AssignmentSubmissionModel?> getCachedSubmission(String submissionId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'assignment_submissions',
        where: 'id = ?',
        whereArgs: [submissionId],
      );
      if (results.isEmpty) return null;
      final sub = results.first;

      // NEW: Query files from submission_files table
      final files = await getCachedSubmissionFiles(submissionId);

      return AssignmentSubmissionModel(
        id: sub['id'] as String,
        assignmentId: sub['assignment_id'] as String,
        studentId: sub['student_id'] as String,
        studentName: sub['student_name'] as String? ?? '',
        status: sub['status'] as String,
        textContent: sub['text_content'] as String?,
        submittedAt: sub['submitted_at'] != null ? DateTime.parse(sub['submitted_at'] as String) : null,
        isLate: (sub['is_late'] as int?) == 1,
        score: sub['score'] as int?,
        feedback: sub['feedback'] as String?,
        gradedAt: sub['graded_at'] != null ? DateTime.parse(sub['graded_at'] as String) : null,
        files: files,
        createdAt: DateTime.parse(sub['created_at'] as String),
        updatedAt: DateTime.parse(sub['updated_at'] as String),
      );
    } catch (e) {
      throw CacheException('Failed to get cached submission: $e');
    }
  }

  /// NEW: Get cached submission files from SQLite
  @override
  Future<List<SubmissionFileModel>> getCachedSubmissionFiles(String submissionId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'submission_files',
        where: 'submission_id = ? AND deleted_at IS NULL',
        whereArgs: [submissionId],
        orderBy: 'uploaded_at ASC',
      );
      return results.map((row) => SubmissionFileModel.fromMap(row)).toList();
    } catch (e) {
      throw CacheException('Failed to fetch submission files: $e');
    }
  }

  @override
  Future<List<SubmissionListItemModel>> getCachedSubmissions(String assignmentId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'assignment_submissions',
        where: 'assignment_id = ?',
        whereArgs: [assignmentId],
        orderBy: 'created_at DESC',
      );
      if (results.isEmpty) throw CacheException('No cached submissions for assignment $assignmentId');
      return results.map((row) => SubmissionListItemModel(
        id: row['id'] as String,
        studentId: row['student_id'] as String,
        studentName: row['student_name'] as String? ?? '',
        status: row['status'] as String,
        submittedAt: row['submitted_at'] != null ? DateTime.parse(row['submitted_at'] as String) : null,
        isLate: (row['is_late'] as int?) == 1,
        score: row['score'] as int?,
      )).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }
}