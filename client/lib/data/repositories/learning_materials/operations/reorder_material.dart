import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<LearningMaterial>> reorderMaterial(
  LearningMaterialLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String materialId,
  required int newOrderIndex,
}) async {
  try {
    final now = DateTime.now();

    final existing = await localDataSource.getCachedMaterialDetail(materialId);
    final optimisticModel = LearningMaterialModel(
      id: materialId,
      classId: existing.classId,
      title: existing.title,
      description: existing.description,
      contentText: existing.contentText,
      orderIndex: newOrderIndex,
      fileCount: existing.fileCount,
      createdAt: existing.createdAt,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateMaterialFields(
        materialId,
        {'order_index': newOrderIndex},
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.update,
          payload: {
            'id': materialId,
            'order_index': newOrderIndex,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
