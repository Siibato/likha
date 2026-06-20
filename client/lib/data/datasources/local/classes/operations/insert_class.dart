import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/classes/class_model.dart';

Future<void> insertClass(
  LocalDatabase localDatabase,
  ClassModel classModel, {
  Transaction? txn,
}) async {
  try {
    final map = classModel.toMap();
    map[CommonCols.syncStatus] = SyncStatus.pending.dbValue;

    if (txn != null) {
      await txn.insert(DbTables.classes, map);
    } else {
      final db = await localDatabase.database;
      await db.insert(DbTables.classes, map);
    }
  } catch (e) {
    throw CacheException('Failed to insert class locally: $e');
  }
}
