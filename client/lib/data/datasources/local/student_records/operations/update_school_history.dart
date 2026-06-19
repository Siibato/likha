import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/student_records/school_history_model.dart';

Future<void> updateSchoolHistory(
  LocalDatabase localDatabase,
  SchoolHistoryModel model, {
  Transaction? txn,
}) async {
  try {
    final map = model.toJson();
    map[CommonCols.updatedAt] = DateTime.now().toIso8601String();
    map[CommonCols.syncStatus] = SyncStatus.pending.dbValue;

    if (txn != null) {
      await txn.update(
        DbTables.studentSchoolHistory,
        map,
        where: '${CommonCols.id} = ?',
        whereArgs: [map[CommonCols.id]],
      );
    } else {
      final db = await localDatabase.database;
      await db.update(
        DbTables.studentSchoolHistory,
        map,
        where: '${CommonCols.id} = ?',
        whereArgs: [map[CommonCols.id]],
      );
    }
  } catch (e) {
    throw CacheException('Failed to update school history locally: $e');
  }
}
