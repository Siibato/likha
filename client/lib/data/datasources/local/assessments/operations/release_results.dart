import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> releaseResults(
  LocalDatabase localDatabase,
  String assessmentId, {
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now();
    final data = {
      AssessmentsCols.resultsReleased: 1,
      CommonCols.syncStatus: 'pending',
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.cachedAt: now.toIso8601String(),
    };
    const where = '${CommonCols.id} = ?';
    final whereArgs = [assessmentId];

    if (txn != null) {
      await txn.update(DbTables.assessments, data, where: where, whereArgs: whereArgs);
    } else {
      final db = await localDatabase.database;
      await db.update(DbTables.assessments, data, where: where, whereArgs: whereArgs);
    }
  } catch (e) {
    throw CacheException('Failed to release results locally: $e');
  }
}
