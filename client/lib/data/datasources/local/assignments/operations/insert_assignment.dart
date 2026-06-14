import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> insertAssignment(
  LocalDatabase localDatabase,
  AssignmentModel assignment, {
  Transaction? txn,
}) async {
  try {
    final map = assignment.toMap();
    map[CommonCols.needsSync] = 1;

    if (txn != null) {
      await txn.insert(DbTables.assignments, map);
    } else {
      final db = await localDatabase.database;
      await db.insert(DbTables.assignments, map);
    }
  } catch (e) {
    throw CacheException('Failed to insert assignment locally: $e');
  }
}
