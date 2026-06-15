import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> updateQuestion(
  LocalDatabase localDatabase,
  String questionId,
  Map<String, dynamic> updates,
  bool isOfflineMutation, {
  Transaction? txn,
}) async {
  try {
    updates[CommonCols.updatedAt] = DateTime.now().toIso8601String();
    updates[CommonCols.syncStatus] = isOfflineMutation ? 'pending' : 'synced';
    const where = '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL';
    final whereArgs = [questionId];

    if (txn != null) {
      await txn.update(DbTables.assessmentQuestions, updates, where: where, whereArgs: whereArgs);
    } else {
      final db = await localDatabase.database;
      await db.update(DbTables.assessmentQuestions, updates, where: where, whereArgs: whereArgs);
    }
  } catch (e) {
    throw CacheException('Failed to update question locally: $e');
  }
}
