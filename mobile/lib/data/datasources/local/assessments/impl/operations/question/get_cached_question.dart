import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assessments/question_model.dart';

Future<QuestionModel?> getCachedQuestionOp(
  LocalDatabase localDatabase,
  String questionId,
) async {
  try {
    final db = await localDatabase.database;
    final rows = await db.query(
      DbTables.assessmentQuestions,
      where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [questionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return QuestionModel.fromMap(rows.first);
  } catch (e) {
    throw CacheException('Failed to get cached question: $e');
  }
}
