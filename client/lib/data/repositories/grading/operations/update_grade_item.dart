import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';

ResultFuture<MutationResult<void>> updateGradeItem(
  GradingLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String id,
  required Map<String, dynamic> data,
}) async {
  try {
    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateItemFields(id, data, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.gradeItem,
          operation: SyncOperation.update,
          payload: {
            'id': id,
            ...data,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: DateTime.now(),
        ),
        txn: txn,
      );
    });

    return Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
