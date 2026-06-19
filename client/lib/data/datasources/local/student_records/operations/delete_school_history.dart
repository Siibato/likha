import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> deleteSchoolHistory(
  LocalDatabase localDatabase,
  String historyId, {
  Transaction? txn,
}) async {
  try {
    final values = {
      CommonCols.deletedAt: DateTime.now().toIso8601String(),
      CommonCols.updatedAt: DateTime.now().toIso8601String(),
      CommonCols.syncStatus: SyncStatus.pending.dbValue,
    };

    if (txn != null) {
      await txn.update(
        DbTables.studentSchoolHistory,
        values,
        where: '${CommonCols.id} = ?',
        whereArgs: [historyId],
      );
    } else {
      final db = await localDatabase.database;
      await db.update(
        DbTables.studentSchoolHistory,
        values,
        where: '${CommonCols.id} = ?',
        whereArgs: [historyId],
      );
    }
  } catch (e) {
    throw CacheException('Failed to soft-delete school history locally: $e');
  }
}
