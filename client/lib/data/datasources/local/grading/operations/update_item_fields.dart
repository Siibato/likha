import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> updateItemFields(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String id,
  Map<String, dynamic> data, {
  Transaction? txn,
}) async {
  final now = DateTime.now();
  final updates = <String, dynamic>{
    CommonCols.updatedAt: now.toIso8601String(),
    CommonCols.cachedAt: now.toIso8601String(),
    CommonCols.syncStatus: 'pending',
  };
  if (data.containsKey('title')) {
    updates[GradeItemsCols.title] = data['title'];
  }
  if (data.containsKey('component')) {
    updates[GradeItemsCols.component] = data['component'];
  }
  if (data.containsKey('total_points')) {
    updates[GradeItemsCols.totalPoints] = data['total_points'];
  }
  if (data.containsKey('order_index')) {
    updates[GradeItemsCols.orderIndex] = data['order_index'];
  }

  Future<void> doWrite(DatabaseExecutor executor) async {
    await executor.update(
      DbTables.gradeItems,
      updates,
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
  }

  if (txn != null) {
    await doWrite(txn);
  } else {
    final db = await localDatabase.database;
    await db.transaction((innerTxn) async {
      await doWrite(innerTxn);
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeItem,
        operation: SyncOperation.update,
        payload: {'id': id, ...data},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: innerTxn);
    });
  }
}
