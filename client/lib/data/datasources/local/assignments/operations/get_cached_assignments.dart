import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';

Future<List<AssignmentModel>> getCachedAssignments(
  LocalDatabase localDatabase,
  String classId,
  bool publishedOnly,
  String? studentId,
) async {
  try {
    final db = await localDatabase.database;
    final where = publishedOnly
        ? '${AssignmentsCols.classId} = ? AND ${AssignmentsCols.isPublished} = 1 AND ${CommonCols.deletedAt} IS NULL'
        : '${AssignmentsCols.classId} = ? AND ${CommonCols.deletedAt} IS NULL';
    final results = await db.query(
      DbTables.assignments,
      where: where,
      whereArgs: [classId],
      orderBy: '${AssignmentsCols.orderIndex} ASC',
    );
    if (results.isEmpty) throw CacheException('No cached assignments found');

    // If no studentId provided (teacher path), enrich with submission counts
    if (studentId == null) {
      final enriched = <AssignmentModel>[];
      for (final row in results) {
        final base = AssignmentModel.fromMap(row);
        // Compute dynamic submissionCount and gradedCount
        final countRow = await db.rawQuery(
          'SELECT COUNT(*) as total, SUM(CASE WHEN status IN (\'graded\',\'returned\') THEN 1 ELSE 0 END) as graded FROM ${DbTables.assignmentSubmissions} WHERE assignment_id = ? AND deleted_at IS NULL',
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
          allowsTextSubmission: base.allowsTextSubmission,
          allowsFileSubmission: base.allowsFileSubmission,
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
          termNumber: base.termNumber,
          component: base.component,
          createdAt: base.createdAt,
          updatedAt: base.updatedAt,
          cachedAt: base.cachedAt,
          syncStatus: base.syncStatus,
          deletedAt: base.deletedAt,
        ));
      }
      return enriched;
    }

    // Enrich each assignment with per-student submission data and dynamic counts (E8, E2)
    final enriched = <AssignmentModel>[];
    for (final row in results) {
      final base = AssignmentModel.fromMap(row);
      final sub = await _getStudentSubmissionForAssignment(db, base.id, studentId);

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
        allowsTextSubmission: base.allowsTextSubmission,
        allowsFileSubmission: base.allowsFileSubmission,
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
        termNumber: base.termNumber,
        component: base.component,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
        cachedAt: base.cachedAt,
        syncStatus: base.syncStatus,
        deletedAt: base.deletedAt,
      ));
    }
    return enriched;
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}

Future<(String submissionId, String status, int? score)?> _getStudentSubmissionForAssignment(
  dynamic db,
  String assignmentId,
  String studentId,
) async {
  try {
    final results = await db.query(
      DbTables.assignmentSubmissions,
      columns: [CommonCols.id, AssignmentSubmissionsCols.status, AssignmentSubmissionsCols.points],
      where: '${AssignmentSubmissionsCols.assignmentId} = ? AND ${AssignmentSubmissionsCols.studentId} = ? AND ${CommonCols.deletedAt} IS NULL',
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
