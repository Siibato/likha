import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<void>> deleteFile(
  LearningMaterialLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String fileId,
}) async {
  try {
    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.softDeleteFile(fileId, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.materialFile,
          operation: SyncOperation.delete,
          payload: {'file_id': fileId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
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
