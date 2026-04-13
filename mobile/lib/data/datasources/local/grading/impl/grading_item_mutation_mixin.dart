import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/sync/sync_queue.dart';
import '../grading_local_datasource_base.dart';

mixin GradingItemMutationMixin on GradingLocalDataSourceBase {
  @override
  Future<void> updateItemFields(String id, Map<String, dynamic> data) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    final updates = <String, dynamic>{
      CommonCols.updatedAt: now.toIso8601String(),
      CommonCols.cachedAt: now.toIso8601String(),
      CommonCols.needsSync: 1,
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
    await db.transaction((txn) async {
      await txn.update(
        DbTables.gradeItems,
        updates,
        where: '${CommonCols.id} = ?',
        whereArgs: [id],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeItem,
        operation: SyncOperation.update,
        payload: {'id': id, ...data},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }

  @override
  Future<void> softDeleteItem(String id) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        DbTables.gradeItems,
        {
          CommonCols.deletedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [id],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeItem,
        operation: SyncOperation.delete,
        payload: {'id': id},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }
}
