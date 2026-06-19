import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/student_records/core_values_record_model.dart';

Future<void> insertCoreValues(
  LocalDatabase localDatabase,
  CoreValuesRecordModel model, {
  Transaction? txn,
}) async {
  try {
    final map = model.toJson();
    final now = DateTime.now().toIso8601String();
    map[CommonCols.createdAt] = now;
    map[CommonCols.updatedAt] = now;
    map[CommonCols.syncStatus] = SyncStatus.pending.dbValue;

    if (txn != null) {
      await txn.insert(DbTables.coreValuesRecords, map);
    } else {
      final db = await localDatabase.database;
      await db.insert(DbTables.coreValuesRecords, map);
    }
  } catch (e) {
    throw CacheException('Failed to insert core values locally: $e');
  }
}
