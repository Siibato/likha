import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

ResultFuture<MutationResult<TableOfSpecifications>> updateTos(
  TosLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String tosId,
  required Map<String, dynamic> data,
}) async {
  try {
    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateTosFields(tosId, data, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.tableOfSpecifications,
          operation: SyncOperation.update,
          payload: {
            'id': tosId,
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

    final updated = await localDataSource.getTosById(tosId);
    if (updated == null) {
      return const Left(CacheFailure('TOS not found after update'));
    }
    return Right(MutationResult(entity: updated, status: SyncStatus.pending));
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
