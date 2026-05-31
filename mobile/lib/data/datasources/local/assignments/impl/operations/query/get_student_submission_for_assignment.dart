import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<(String submissionId, String status, int? score)?> getStudentSubmissionForAssignmentOp(
  LocalDatabase localDatabase,
  String assignmentId,
  String studentId,
) async {
  try {
    final db = await localDatabase.database;
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
