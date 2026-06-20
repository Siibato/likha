import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> deleteAssignment(
  LocalDatabase localDatabase,
  String assignmentId, {
  Transaction? txn,
}) async {
  try {
    final updateMap = {CommonCols.deletedAt: DateTime.now().toIso8601String()};
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
    throw CacheException('Failed to delete assignment locally: $e');
  }
}
