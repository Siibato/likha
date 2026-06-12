import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> updateQuestion(
  LocalDatabase localDatabase,
  String questionId,
  Map<String, dynamic> updates,
  bool isOfflineMutation,
) async {
  try {
    final db = await localDatabase.database;
    updates[CommonCols.updatedAt] = DateTime.now().toIso8601String();
    updates[CommonCols.needsSync] = isOfflineMutation ? 1 : 0;
    await db.update(DbTables.assessmentQuestions, updates, where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL', whereArgs: [questionId]);
  } catch (e) {
    throw CacheException('Failed to update question locally: $e');
  }
}
