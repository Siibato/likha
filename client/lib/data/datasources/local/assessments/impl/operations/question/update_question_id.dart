import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> updateQuestionIdOp(
  LocalDatabase localDatabase,
  String localId,
  String serverId,
) async {
  try {
    final db = await localDatabase.database;
    await db.update(DbTables.assessmentQuestions, {CommonCols.id: serverId}, where: '${CommonCols.id} = ?', whereArgs: [localId]);
  } catch (e) {
    throw CacheException('Failed to update question ID: $e');
  }
}
