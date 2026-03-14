import 'dart:io';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart'
    show AssignmentSubmissionModel, SubmissionListItemModel;
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:path_provider/path_provider.dart';
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
            'SELECT COUNT(*) as total, SUM(CASE WHEN status IN (\'graded\',\'returned\') THEN 1 ELSE 0 END) as graded FROM assignment_submissions WHERE assignment_id = ? AND deleted_at IS NULL',
            [base.id],
          );
          final liveCount = countRow.first['total'] as int? ?? 0;
          final liveGraded = countRow.first['graded'] as int? ?? 0;
          // Prefer live count (from local rows); fall back to server-synced stored value when table is empty
          final submissionCount = liveCount > 0 ? liveCount : base.submissionCount;
          final gradedCount = liveGraded > 0 ? liveGraded : base.gradedCount;

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
          'SELECT COUNT(*) as total, SUM(CASE WHEN status IN (\'graded\',\'returned\') THEN 1 ELSE 0 END) as graded FROM assignment_submissions WHERE assignment_id = ? AND deleted_at IS NULL',
          [base.id],
        );
        final liveCount = countRow.first['total'] as int? ?? 0;
        final liveGraded = countRow.first['graded'] as int? ?? 0;
        // Prefer live count (from local rows); fall back to server-synced stored value when table is empty
        final submissionCount = liveCount > 0 ? liveCount : base.submissionCount;
        final gradedCount = liveGraded > 0 ? liveGraded : base.gradedCount;

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
          submissionStatus: sub?.$2 ?? base.submissionStatus,
          submissionId: sub?.$1 ?? base.submissionId,
          score: sub?.$3 ?? base.score,
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
        'SELECT COUNT(*) as total, SUM(CASE WHEN status IN (\'graded\',\'returned\') THEN 1 ELSE 0 END) as graded FROM assignment_submissions WHERE assignment_id = ? AND deleted_at IS NULL',
        [base.id],
      );
      final liveCount = countRow.first['total'] as int? ?? 0;
      final liveGraded = countRow.first['graded'] as int? ?? 0;
      // Prefer live count (from local rows); fall back to server-synced stored value when table is empty
      final submissionCount = liveCount > 0 ? liveCount : base.submissionCount;
      final gradedCount = liveGraded > 0 ? liveGraded : base.gradedCount;

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

  /// Get cached submission files from SQLite with auto-repair
  /// If local_path is empty but file exists on disk, reconstructs and restores the path.
  /// This ensures file cache state persists correctly after app restart.
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

      final models = <SubmissionFileModel>[];
      for (final row in results) {
        final fileId = row['id'] as String;
        final fileName = row['file_name'] as String?;
        var localPath = row['local_path'] as String?;

        // Auto-repair: if local_path is empty but file exists on disk, restore it
        if ((localPath == null || localPath.isEmpty) && fileName != null) {
          final expectedPath = await _getExpectedSubmissionFilePath(fileId, fileName);
          if (expectedPath != null) {
            final file = File(expectedPath);
            if (await file.exists()) {
              await db.update(
                'submission_files',
                {'local_path': expectedPath},
                where: 'id = ?',
                whereArgs: [fileId],
              );
              localPath = expectedPath;
            }
          }
        }

        final updatedRow = Map<String, dynamic>.from(row);
        updatedRow['local_path'] = localPath;
        models.add(SubmissionFileModel.fromMap(updatedRow));
      }
      return models;
    } catch (e) {
      throw CacheException('Failed to fetch submission files: $e');
    }
  }

  @override
  Future<List<SubmissionListItemModel>> getCachedSubmissions(String assignmentId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.rawQuery('''
        SELECT s.*, u.full_name as student_name, u.username as student_username
        FROM assignment_submissions s
        LEFT JOIN users u ON u.id = s.student_id
        WHERE s.assignment_id = ? AND s.deleted_at IS NULL
        ORDER BY CASE WHEN s.submitted_at IS NULL THEN 1 ELSE 0 END ASC, s.submitted_at ASC
      ''', [assignmentId]);
      if (results.isEmpty) return [];
      return results.map((row) => SubmissionListItemModel(
        id: row['id'] as String,
        studentId: row['student_id'] as String,
        studentName: row['student_name'] as String? ?? '',
        studentUsername: row['student_username'] as String? ?? '',
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

  /// Soft delete an assignment locally by setting deleted_at to current timestamp
  @override
  Future<void> deleteAssignmentLocal({required String assignmentId}) async {
    try {
      final db = await localDatabase.database;
      await db.update(
        'assignments',
        {'deleted_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [assignmentId],
      );
    } catch (e) {
      throw CacheException('Failed to delete assignment locally: $e');
    }
  }

  /// Reconstruct expected file path from fileId and fileName.
  /// Uses naming convention: {nameWithoutExt}-{shortId8}.{ext}
  /// Example: report.pdf with fileId cfa3d566-... → report-cfa3d566.pdf
  /// Matches cacheFileBytes() naming in assignment_file_mixin.dart lines 186-190.
  Future<String?> _getExpectedSubmissionFilePath(String fileId, String fileName) async {
    try {
      final appDirDoc = await getApplicationDocumentsDirectory();
      final submissionFilesDir = Directory('${appDirDoc.path}/submission_files');
      final shortId = fileId.substring(0, 8);
      final dotIndex = fileName.lastIndexOf('.');
      final localFileName = dotIndex > 0
          ? '${fileName.substring(0, dotIndex)}-$shortId${fileName.substring(dotIndex)}'
          : '$fileName-$shortId';
      return '${submissionFilesDir.path}/$localFileName';
    } catch (e) {
      return null;
    }
  }
}