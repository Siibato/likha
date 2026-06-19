import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/student_records/school_history_model.dart';

Future<void> cacheSchoolHistory(
  LocalDatabase localDatabase,
  List<SchoolHistoryModel> records, {
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now().toIso8601String();
    Future<void> doUpsert(dynamic executor) async {
      for (final record in records) {
        final map = record.toJson();
        map[CommonCols.cachedAt] = now;
        map[CommonCols.syncStatus] = 'synced';
        final updated = await executor.update(
          DbTables.studentSchoolHistory,
          map,
          where: '${CommonCols.id} = ?',
          whereArgs: [map[CommonCols.id]],
        );
        if (updated == 0) {
          await executor.insert(DbTables.studentSchoolHistory, map);
        }
      }
    }

    if (txn != null) {
      await doUpsert(txn);
    } else {
      final db = await localDatabase.database;
      await db.transaction((t) => doUpsert(t));
    }
  } catch (e) {
    throw CacheException('Failed to cache school history: $e');
  }
}
