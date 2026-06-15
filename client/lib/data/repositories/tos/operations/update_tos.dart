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

ResultFuture<MutationResult<TableOfSpecifications>> updateTos(
  TosLocalDataSource localDataSource,
  SyncQueue syncQueue,
  TosRemoteDataSource remoteDataSource, {
  required String tosId,
  required Map<String, dynamic> data,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final current = await localDataSource.getTosById(tosId);
    if (current == null) {
      return const Left(CacheFailure('TOS not found'));
    }

    final optimisticModel = TosModel(
      id: current.id,
      classId: current.classId,
      gradingPeriodNumber: current.gradingPeriodNumber,
      title: data['title'] as String? ?? current.title,
      classificationMode: data['classification_mode'] as String? ?? current.classificationMode,
      totalItems: data['total_items'] != null ? (data['total_items'] as num).toInt() : current.totalItems,
      timeUnit: data['time_unit'] as String? ?? current.timeUnit,
      easyPercentage: data['easy_percentage'] != null ? (data['easy_percentage'] as num).toDouble() : current.easyPercentage,
      mediumPercentage: data['medium_percentage'] != null ? (data['medium_percentage'] as num).toDouble() : current.mediumPercentage,
      hardPercentage: data['hard_percentage'] != null ? (data['hard_percentage'] as num).toDouble() : current.hardPercentage,
      createdAt: current.createdAt,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateTosFields(tosId, data, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.tableOfSpecifications,
          operation: SyncOperation.update,
          payload: {
            'id': tosId,
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

    fireRemoteWrite<TosModel>(
      remote: () => remoteDataSource.updateTos(
        tosId: tosId,
        data: data,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverModel) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.tableOfSpecifications,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [tosId],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }

        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.tableOfSpecifications,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [tosId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
