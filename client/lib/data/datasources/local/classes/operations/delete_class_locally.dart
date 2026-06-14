import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> deleteClassLocally(
  LocalDatabase localDatabase,
  String classId, {
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now();
    final values = <String, dynamic>{
      ClassesCols.isArchived: 1,
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.syncStatus: 'pending',
      CommonCols.cachedAt: now.toIso8601String(),
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
    throw CacheException('Failed to delete class locally: $e');
  }
}
