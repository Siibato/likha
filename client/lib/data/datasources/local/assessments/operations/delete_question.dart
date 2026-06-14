import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> deleteQuestion(
  LocalDatabase localDatabase,
  String questionId,
) async {
  try {
    final db = await localDatabase.database;
    await db.update(
      DbTables.assessmentQuestions,
      {
        CommonCols.deletedAt: DateTime.now().toIso8601String(),
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
        CommonCols.syncStatus: 'pending',
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [questionId],
    );
  } catch (e) {
    throw CacheException('Failed to delete question locally: $e');
  }
}
