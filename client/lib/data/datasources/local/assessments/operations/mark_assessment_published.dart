import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> markAssessmentPublished(
  LocalDatabase localDatabase,
  String assessmentId, {
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now();
    final data = {
      AssessmentsCols.isPublished: 1,
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.cachedAt: now.toIso8601String(),
      CommonCols.syncStatus: 'pending',
    };
    const where = '${CommonCols.id} = ?';
    final whereArgs = [assessmentId];

    if (txn != null) {
      await txn.update('assessments', data, where: where, whereArgs: whereArgs);
    } else {
      final db = await localDatabase.database;
      await db.update('assessments', data, where: where, whereArgs: whereArgs);
    }
  } catch (e) {
    throw CacheException('Failed to mark assessment as published locally: $e');
  }
}
