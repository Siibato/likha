import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> updateChoiceIdsOp(
  LocalDatabase localDatabase,
  String questionId,
  Map<String, String> idMapping,
) async {
  try {
    final db = await localDatabase.database;
    for (final entry in idMapping.entries) {
      await db.update(
        DbTables.questionChoices,
        {CommonCols.id: entry.value},
        where: '${CommonCols.id} = ?',
        whereArgs: [entry.key],
      );
    }
  } catch (e) {
    throw CacheException('Failed to update choice IDs: $e');
  }
}
