import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';

ResultFuture<MutationResult<void>> deleteGradeItem(
  GradingLocalDataSource localDataSource,
  SyncQueue syncQueue,
  DataEventBus dataEventBus, {
  required String id,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final db = await localDataSource.localDatabase.database;

    // Look up classId before deleting so we can emit the correct event
    final itemRows = await db.query(
      DbTables.gradeItems,
      where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    final classId = itemRows.isNotEmpty
        ? GradeItemModel.fromMap(itemRows.first).classId
        : '';

    await db.transaction((txn) async {
      await localDataSource.softDeleteItem(id, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.gradeItem,
          operation: SyncOperation.delete,
          payload: {'id': id},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    dataEventBus.notifyGradesChanged(classId);

    return const Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
