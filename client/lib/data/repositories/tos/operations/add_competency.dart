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
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<TosCompetency>> addCompetency(
  TosLocalDataSource localDataSource,
  SyncQueue syncQueue,
  TosRemoteDataSource remoteDataSource, {
  required String tosId,
  required Map<String, dynamic> data,
}) async {
  try {
    final competencyId = const Uuid().v4();
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final optimisticModel = CompetencyModel(
      id: competencyId,
      tosId: tosId,
      competencyCode: data['competency_code'] as String?,
      competencyText: data['competency_text'] as String,
      timeUnitsTaught: (data['time_units_taught'] as num?)?.toInt() ?? (data['days_taught'] as num).toInt(),
      orderIndex: (data['order_index'] as num?)?.toInt() ?? 0,
      easyCount: data['easy_count'] as int?,
      mediumCount: data['medium_count'] as int?,
      hardCount: data['hard_count'] as int?,
      createdAt: now,
      updatedAt: now,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.saveCompetency(optimisticModel, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.tosCompetency,
          operation: SyncOperation.create,
          payload: {
            ...optimisticModel.toPayload(),
            'tos_id': tosId,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<CompetencyModel>(
      remote: () => remoteDataSource.addCompetency(
        tosId: tosId,
        data: {
          ...data,
          'id': competencyId,
        },
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverModel) async {
        final db = await localDataSource.localDatabase.database;

        if (serverModel.id != competencyId) {
          await db.update(
            DbTables.tosCompetencies,
            {CommonCols.id: serverModel.id},
            where: '${CommonCols.id} = ?',
            whereArgs: [competencyId],
          );
        }

        await db.update(
          DbTables.tosCompetencies,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [serverModel.id],
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

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
