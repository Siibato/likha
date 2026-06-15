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

ResultFuture<MutationResult<List<TosCompetency>>> bulkAddCompetencies(
  TosLocalDataSource localDataSource,
  SyncQueue syncQueue,
  TosRemoteDataSource remoteDataSource, {
  required String tosId,
  required List<Map<String, dynamic>> competencies,
}) async {
  try {
    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();
    final models = <CompetencyModel>[];

    for (var i = 0; i < competencies.length; i++) {
      final data = competencies[i];
      final id = const Uuid().v4();
      models.add(CompetencyModel(
        id: id,
        tosId: tosId,
        competencyCode: data['competency_code'] as String?,
        competencyText: data['competency_text'] as String,
        timeUnitsTaught: (data['time_units_taught'] as num?)?.toInt() ?? (data['days_taught'] as num).toInt(),
        orderIndex: (data['order_index'] as num?)?.toInt() ?? i,
        easyCount: data['easy_count'] as int?,
        mediumCount: data['medium_count'] as int?,
        hardCount: data['hard_count'] as int?,
        createdAt: now,
        updatedAt: now,
      ));
    }

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.bulkSaveCompetencies(models, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.tosCompetency,
          operation: SyncOperation.create,
          payload: {
            'tos_id': tosId,
            'competencies': competencies,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<List<CompetencyModel>>(
      remote: () => remoteDataSource.bulkAddCompetencies(
        tosId: tosId,
        competencies: competencies,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverModels) async {
        final db = await localDataSource.localDatabase.database;
        for (var i = 0; i < serverModels.length && i < models.length; i++) {
          if (serverModels[i].id != models[i].id) {
            await db.update(
              DbTables.tosCompetencies,
              {CommonCols.id: serverModels[i].id},
              where: '${CommonCols.id} = ?',
              whereArgs: [models[i].id],
            );
          }
          await db.update(
            DbTables.tosCompetencies,
            {CommonCols.syncStatus: SyncStatus.synced.dbValue},
            where: '${CommonCols.id} = ?',
            whereArgs: [serverModels[i].id],
          );
        }
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }

        final db = await localDataSource.localDatabase.database;
        for (final model in models) {
          await db.update(
            DbTables.tosCompetencies,
            {CommonCols.syncStatus: SyncStatus.failed.dbValue},
            where: '${CommonCols.id} = ?',
            whereArgs: [model.id],
          );
        }
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: models, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
