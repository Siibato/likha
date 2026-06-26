import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<String?> getAssignmentIdForSubmission(
  LocalDatabase localDatabase,
  String submissionId,
) async {
  try {
    final db = await localDatabase.database;
    final result = await db.query(
      DbTables.assignmentSubmissions,
      columns: [AssignmentSubmissionsCols.assignmentId],
      where: '${CommonCols.id} = ?',
      whereArgs: [submissionId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first[AssignmentSubmissionsCols.assignmentId] as String?;
  } catch (e) {
    throw CacheException('Failed to get assignmentId for submission: $e');
  }
}
