import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<bool?> hasStudentSubmittedAssessmentOp(
  LocalDatabase localDatabase,
  String assessmentId,
  String studentId,
) async {
  try {
    final db = await localDatabase.database;
    final result = await db.query(
      'assessment_submissions',
      columns: ['submitted_at'],
      where: 'assessment_id = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [assessmentId, studentId],
    );
    if (result.isEmpty) {
      return null;
    }
    final isSubmitted = result.first['submitted_at'] != null;
    return isSubmitted;
  } catch (e) {
    throw CacheException('Failed to check submission status: $e');
  }
}
