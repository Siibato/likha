import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> clearAllCacheOp(LocalDatabase localDatabase) async {
  try {
    final db = await localDatabase.database;
    await db.delete(DbTables.gradeScores);
    await db.delete(DbTables.gradeItems);
    await db.delete(DbTables.gradeRecord);
    await db.delete(DbTables.periodGrades);
    await db.delete(DbTables.studentResultsCache);
  } catch (e) {
    throw CacheException('Failed to clear grading cache: $e');
  }
}
