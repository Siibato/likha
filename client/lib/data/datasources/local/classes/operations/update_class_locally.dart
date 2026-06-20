import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> updateClassLocally(
  LocalDatabase localDatabase,
  String classId, {
  String? title,
  String? description,
  bool? isAdvisory,
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now();
    final values = <String, dynamic>{
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.syncStatus: 'pending',
      CommonCols.cachedAt: now.toIso8601String(),
      if (title != null) ClassesCols.title: title,
      if (description != null) ClassesCols.description: description,
      if (isAdvisory != null) ClassesCols.isAdvisory: isAdvisory ? 1 : 0,
    };
    const whereClause = '${CommonCols.id} = ?';
    final whereArgs = [classId];

    if (txn != null) {
      await txn.update(
        DbTables.classes,
        values,
        where: whereClause,
        whereArgs: whereArgs,
      );
    } else {
      final db = await localDatabase.database;
      await db.update(
        DbTables.classes,
        values,
        where: whereClause,
        whereArgs: whereArgs,
      );
    }
  } catch (e) {
    throw CacheException('Failed to update class locally: $e');
  }
}
