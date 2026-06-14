import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';

Future<void> cacheAssignmentDetail(
  LocalDatabase localDatabase,
  AssignmentModel assignment,
) async {
  try {
    final db = await localDatabase.database;
    final map = assignment.toMap();
    map['cached_at'] = DateTime.now().toIso8601String();
    map['sync_status'] = SyncStatus.synced.dbValue;
    // Use update-first pattern to avoid CASCADE DELETE on assignment_submissions
    final updated = await db.update(DbTables.assignments, map, where: '${CommonCols.id} = ?', whereArgs: [map[CommonCols.id]]);
    if (updated == 0) {
      await db.insert(DbTables.assignments, map);
    }
  } catch (e) {
    throw CacheException('Failed to cache assignment detail: $e');
  }
}
