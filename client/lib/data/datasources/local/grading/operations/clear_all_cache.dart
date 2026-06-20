import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> clearAllCache(LocalDatabase localDatabase) async {
  try {
    final db = await localDatabase.database;
    await db.delete(DbTables.gradeScores);
    await db.delete(DbTables.gradeItems);
    await db.delete(DbTables.gradeRecord);
    await db.delete(DbTables.termGrades);
    await db.delete(DbTables.studentResultsCache);
    await db.delete(
      DbTables.syncMetadata,
      where: "${SyncMetadataCols.key} LIKE 'grade_summary:%'",
    );
    await db.delete(
      DbTables.syncMetadata,
      where: "${SyncMetadataCols.key} LIKE 'sf9:%'",
    );
    await db.delete(
      DbTables.syncMetadata,
      where: "${SyncMetadataCols.key} LIKE 'sf10:%'",
    );
  } catch (e) {
    throw CacheException('Failed to clear grading cache: $e');
  }
}
