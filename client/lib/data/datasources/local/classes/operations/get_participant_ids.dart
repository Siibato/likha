import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<Set<String>> getParticipantIds(
  LocalDatabase localDatabase,
  String classId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.classParticipants,
      columns: [ClassParticipantsCols.userId],
      where: '${ClassParticipantsCols.classId} = ? AND ${ClassParticipantsCols.removedAt} IS NULL',
      whereArgs: [classId],
    );
    return results.map((row) => row[ClassParticipantsCols.userId] as String).toSet();
  } catch (e) {
    throw CacheException('Failed to get participant IDs: $e');
  }
}
