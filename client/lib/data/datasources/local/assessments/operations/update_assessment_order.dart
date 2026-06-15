import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> updateAssessmentOrder(
  LocalDatabase localDatabase,
  String assessmentId,
  int orderIndex, {
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now();
    final updateMap = {
      AssessmentsCols.orderIndex: orderIndex,
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.cachedAt: now.toIso8601String(),
      CommonCols.syncStatus: SyncStatus.pending.dbValue,
    };
    if (txn != null) {
      await txn.update(
        DbTables.assessments,
        updateMap,
        where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
        whereArgs: [assessmentId],
      );
    } else {
      final db = await localDatabase.database;
      await db.update(
        DbTables.assessments,
        updateMap,
        where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
        whereArgs: [assessmentId],
      );
    }
  } catch (e) {
    throw CacheException('Failed to update assessment order locally: $e');
  }
}
