import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> deleteQuestion(
  LocalDatabase localDatabase,
  String questionId, {
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now();
    final data = {
      CommonCols.deletedAt: now.toIso8601String(),
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.syncStatus: 'pending',
    };
    const where = '${CommonCols.id} = ?';
    final whereArgs = [questionId];

    if (txn != null) {
      await txn.update(DbTables.assessmentQuestions, data, where: where, whereArgs: whereArgs);
    } else {
      final db = await localDatabase.database;
      await db.update(DbTables.assessmentQuestions, data, where: where, whereArgs: whereArgs);
    }
  } catch (e) {
    throw CacheException('Failed to delete question locally: $e');
  }
}
