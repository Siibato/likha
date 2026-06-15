import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<TosCompetency>> updateCompetency(
  TosLocalDataSource localDataSource,
  SyncQueue syncQueue,
  TosRemoteDataSource remoteDataSource, {
  required String competencyId,
  required Map<String, dynamic> data,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateCompetencyFields(competencyId, data, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.tosCompetency,
          operation: SyncOperation.update,
          payload: {
            'id': competencyId,
            ...data,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<void>(
      remote: () => remoteDataSource.updateCompetency(
        competencyId: competencyId,
        data: data,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (_) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.tosCompetencies,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [competencyId],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }

        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.tosCompetencies,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [competencyId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    final updated = await localDataSource.getCompetencyById(competencyId);
    if (updated != null) {
      return Right(MutationResult(entity: updated, status: SyncStatus.pending));
    }

    return const Left(CacheFailure('Competency not found after update'));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
