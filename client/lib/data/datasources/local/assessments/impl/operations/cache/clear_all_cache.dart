import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> clearAllCacheOp(
  LocalDatabase localDatabase,
) async {
  try {
    final db = await localDatabase.database;
    await db.delete(DbTables.assessments);
    await db.delete(DbTables.assessmentQuestions);
    await db.delete(DbTables.questionChoices);
    await db.delete(DbTables.answerKeys);
    await db.delete(DbTables.answerKeyAcceptableAnswers);
    await db.delete(DbTables.submissionAnswers);
    await db.delete(DbTables.submissionAnswerItems);
    await db.delete(DbTables.assessmentSubmissions);
  } catch (e) {
    throw CacheException('Failed to clear assessment cache: $e');
  }
}
