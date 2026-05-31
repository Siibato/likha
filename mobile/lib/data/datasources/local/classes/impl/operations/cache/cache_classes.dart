import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:sqflite/sqflite.dart';

Future<void> cacheClassesOp(
  LocalDatabase localDatabase,
  List<ClassModel> classes,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      for (final classModel in classes) {
        final map = classModel.toMap();
        map[CommonCols.cachedAt] = DateTime.now().toIso8601String();
        map[CommonCols.needsSync] = 0;
        await txn.insert(DbTables.classes, map, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache classes: $e');
  }
}
