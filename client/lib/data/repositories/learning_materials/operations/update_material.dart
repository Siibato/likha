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
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<LearningMaterial>> updateMaterial(
  LearningMaterialLocalDataSource localDataSource,
  SyncQueue syncQueue,
  LearningMaterialRemoteDataSource remoteDataSource, {
  required String materialId,
  String? title,
  String? description,
  String? contentText,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final existing = await localDataSource.getCachedMaterialDetail(materialId);
    final optimisticModel = LearningMaterialModel(
      id: materialId,
      classId: existing.classId,
      title: title ?? existing.title,
      description: description ?? existing.description,
      contentText: contentText ?? existing.contentText,
      orderIndex: existing.orderIndex,
      fileCount: existing.fileCount,
      createdAt: existing.createdAt,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.updateMaterialFields(
        materialId,
        {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (contentText != null) 'content_text': contentText,
        },
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.update,
          payload: {
            'id': materialId,
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (contentText != null) 'content_text': contentText,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<LearningMaterialModel>(
      remote: () => remoteDataSource.updateMaterial(
        materialId: materialId,
        data: {
          'id': materialId,
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (contentText != null) 'content_text': contentText,
        },
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverModel) async {
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

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
