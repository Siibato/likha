import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';

Future<AssignmentModel> getCachedAssignmentDetailOp(
  LocalDatabase localDatabase,
  String assignmentId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.assignments,
      where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
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
      gradingPeriodNumber: base.gradingPeriodNumber,
      component: base.component,
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
