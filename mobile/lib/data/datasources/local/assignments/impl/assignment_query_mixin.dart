import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart'
    show AssignmentSubmissionModel, SubmissionListItemModel;
import 'package:likha/data/models/assignments/submission_file_model.dart';
import '../assignment_local_datasource_base.dart';

mixin AssignmentQueryMixin on AssignmentLocalDataSourceBase {
  @override
  Future<List<AssignmentModel>> getCachedAssignments(String classId, {bool publishedOnly = false, String? studentId}) async {
    try {
      final db = await localDatabase.database;
      final where = publishedOnly
          ? 'class_id = ? AND is_published = 1 AND deleted_at IS NULL'
          : 'class_id = ? AND deleted_at IS NULL';
      final results = await db.query(
        'assignments',
        where: where,
        whereArgs: [classId],
        orderBy: 'order_index ASC',
      );
      if (results.isEmpty) return [];

      // If no studentId provided (teacher path), enrich with submission counts
      if (studentId == null) {
        final enriched = <AssignmentModel>[];
        for (final row in results) {
          final base = AssignmentModel.fromMap(row);
          // Compute dynamic submissionCount and gradedCount
          final countRow = await db.rawQuery(
            'SELECT COUNT(*) as total, SUM(CASE WHEN status IN ("graded","returned") THEN 1 ELSE 0 END) as graded FROM assignment_submissions WHERE assignment_id = ? AND deleted_at IS NULL',
            [base.id],
          );
          final submissionCount = countRow.first['total'] as int? ?? 0;
          final gradedCount = countRow.first['graded'] as int? ?? 0;

          enriched.add(AssignmentModel(
            id: base.id,
            classId: base.classId,
            title: base.title,
            instructions: base.instructions,
            totalPoints: base.totalPoints,
            submissionType: base.submissionType,
            allowedFileTypes: base.allowedFileTypes,
            maxFileSizeMb: base.maxFileSizeMb,
            dueAt: base.dueAt,
            isPublished: base.isPublished,
            orderIndex: base.orderIndex,
            submissionCount: submissionCount,
            gradedCount: gradedCount,
            submissionStatus: base.submissionStatus,
            submissionId: base.submissionId,
            score: base.score,
            createdAt: base.createdAt,
            updatedAt: base.updatedAt,
            cachedAt: base.cachedAt,
            needsSync: base.needsSync,
            deletedAt: base.deletedAt,
          ));
        }
        return enriched;
      }

      // Enrich each assignment with per-student submission data and dynamic counts (E8, E2)
      final enriched = <AssignmentModel>[];
      for (final row in results) {
        final base = AssignmentModel.fromMap(row);
        final sub = await getStudentSubmissionForAssignment(base.id, studentId);

        // Compute dynamic submissionCount and gradedCount (E8: fixes always-0 from cache)
        final countRow = await db.rawQuery(
          'SELECT COUNT(*) as total, SUM(CASE WHEN status IN ("graded","returned") THEN 1 ELSE 0 END) as graded FROM assignment_submissions WHERE assignment_id = ? AND deleted_at IS NULL',
          [base.id],
        );
        final submissionCount = countRow.first['total'] as int? ?? 0;
        final gradedCount = countRow.first['graded'] as int? ?? 0;

        enriched.add(AssignmentModel(
          id: base.id,
          classId: base.classId,
          title: base.title,
          instructions: base.instructions,
          totalPoints: base.totalPoints,
          submissionType: base.submissionType,
          allowedFileTypes: base.allowedFileTypes,
          maxFileSizeMb: base.maxFileSizeMb,
          dueAt: base.dueAt,
          isPublished: base.isPublished,
          orderIndex: base.orderIndex,
          submissionCount: submissionCount,
          gradedCount: gradedCount,
          submissionStatus: sub?.$2,
          submissionId: sub?.$1,
          score: sub?.$3,
          createdAt: base.createdAt,
          updatedAt: base.updatedAt,
          cachedAt: base.cachedAt,
          needsSync: base.needsSync,
          deletedAt: base.deletedAt,
        ));
      }
      return enriched;
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
      final base = AssignmentModel.fromMap(results.first);

      // Enrich with submission counts
      final countRow = await db.rawQuery(
        'SELECT COUNT(*) as total, SUM(CASE WHEN status IN ("graded","returned") THEN 1 ELSE 0 END) as graded FROM assignment_submissions WHERE assignment_id = ? AND deleted_at IS NULL',
        [base.id],
      );
      final submissionCount = countRow.first['total'] as int? ?? 0;
      final gradedCount = countRow.first['graded'] as int? ?? 0;

      return AssignmentModel(
        id: base.id,
        classId: base.classId,
        title: base.title,
        instructions: base.instructions,
        totalPoints: base.totalPoints,
        submissionType: base.submissionType,
        allowedFileTypes: base.allowedFileTypes,
        maxFileSizeMb: base.maxFileSizeMb,
        dueAt: base.dueAt,
        isPublished: base.isPublished,
        orderIndex: base.orderIndex,
        submissionCount: submissionCount,
        gradedCount: gradedCount,
        submissionStatus: base.submissionStatus,
        submissionId: base.submissionId,
        score: base.score,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
        cachedAt: base.cachedAt,
        needsSync: base.needsSync,
        deletedAt: base.deletedAt,
      );
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<AssignmentSubmissionModel?> getCachedSubmission(String submissionId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.rawQuery('''
        SELECT s.*, u.full_name as student_name
        FROM assignment_submissions s
        LEFT JOIN users u ON u.id = s.student_id
        WHERE s.id = ?
      ''', [submissionId]);
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
        score: sub['points'] as int?,
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
        where: 'submission_id = ?',
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
      final results = await db.rawQuery('''
        SELECT s.*, u.full_name as student_name
        FROM assignment_submissions s
        LEFT JOIN users u ON u.id = s.student_id
        WHERE s.assignment_id = ? AND s.deleted_at IS NULL
        ORDER BY s.created_at DESC
      ''', [assignmentId]);
      if (results.isEmpty) return [];
      return results.map((row) => SubmissionListItemModel(
        id: row['id'] as String,
        studentId: row['student_id'] as String,
        studentName: row['student_name'] as String? ?? '',
        status: row['status'] as String,
        submittedAt: row['submitted_at'] != null ? DateTime.parse(row['submitted_at'] as String) : null,
        isLate: (row['is_late'] as int?) == 1,
        score: row['points'] as int?,
      )).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<(String submissionId, String status, int? score)?> getStudentSubmissionForAssignment(
    String assignmentId,
    String studentId,
  ) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'assignment_submissions',
        columns: ['id', 'status', 'points'],
        where: 'assignment_id = ? AND student_id = ? AND deleted_at IS NULL',
        whereArgs: [assignmentId, studentId],
      );
      if (results.isEmpty) return null;
      final sub = results.first;
      return (
        sub['id'] as String,
        sub['status'] as String,
        sub['points'] as int?,
      );
    } catch (e) {
      throw CacheException('Failed to get student submission: $e');
    }
  }
}