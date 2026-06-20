import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<StartSubmissionResultModel?> getCachedStartResult(
  LocalDatabase localDatabase,
  String submissionId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(DbTables.assessmentSubmissions, where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL', whereArgs: [submissionId]);
    if (results.isEmpty) return null;
    final submission = results.first;
    return StartSubmissionResultModel(
      submissionId: submission['id'] as String,
      startedAt: DateTime.parse(submission['started_at'] as String),
      questions: const [],
    );
  } catch (e) {
    throw CacheException('Failed to get cached start result: $e');
  }
}
