import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> updateAssignmentOrder(
  LocalDatabase localDatabase,
  String assignmentId,
  int orderIndex, {
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now();
    final updateMap = {
      AssignmentsCols.orderIndex: orderIndex,
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.cachedAt: now.toIso8601String(),
      CommonCols.syncStatus: 'pending',
    };
    if (txn != null) {
      await txn.update(
        DbTables.assignments,
        updateMap,
        where: '${CommonCols.id} = ?',
        whereArgs: [assignmentId],
      );
    } else {
      final db = await localDatabase.database;
      await db.update(
        DbTables.assignments,
        updateMap,
        where: '${CommonCols.id} = ?',
        whereArgs: [assignmentId],
      );
    }
  } catch (e) {
    throw CacheException('Failed to update assignment order locally: $e');
  }
}
