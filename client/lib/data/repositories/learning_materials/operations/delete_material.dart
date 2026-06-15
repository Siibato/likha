import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<void>> deleteMaterial(
  LearningMaterialLocalDataSource localDataSource,
  SyncQueue syncQueue,
  LearningMaterialRemoteDataSource remoteDataSource, {
  required String materialId,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.softDeleteMaterial(materialId, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.delete,
          payload: {'id': materialId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<void>(
      remote: () => remoteDataSource.deleteMaterial(
        materialId: materialId,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (_) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.learningMaterials,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [materialId],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }

        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.learningMaterials,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [materialId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return const Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
