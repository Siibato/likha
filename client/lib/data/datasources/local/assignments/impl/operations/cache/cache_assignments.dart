import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';

Future<void> cacheAssignmentsOp(
  LocalDatabase localDatabase,
  List<AssignmentModel> assignments,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      for (final assignment in assignments) {
        final map = assignment.toMap();
        map[CommonCols.cachedAt] = DateTime.now().toIso8601String();
        map[CommonCols.needsSync] = 0;
        // Use update-first pattern to avoid CASCADE DELETE on assignment_submissions
        final updated = await txn.update(DbTables.assignments, map, where: '${CommonCols.id} = ?', whereArgs: [map[CommonCols.id]]);
        if (updated == 0) {
          await txn.insert(DbTables.assignments, map);
        }
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache assignments: $e');
  }
}
