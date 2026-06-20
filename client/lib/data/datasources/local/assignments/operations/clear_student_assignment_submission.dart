import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> clearStudentAssignmentSubmission(
  LocalDatabase localDatabase,
  String assignmentId,
  String studentId,
) async {
  try {
    final db = await localDatabase.database;
    await db.delete(
      DbTables.assignmentSubmissions,
      where:
          '${AssignmentSubmissionsCols.assignmentId} = ? AND ${AssignmentSubmissionsCols.studentId} = ?',
      whereArgs: [assignmentId, studentId],
    );
  } catch (e) {
    throw CacheException('Failed to clear student assignment submission: $e');
  }
}
