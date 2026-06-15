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

ResultFuture<MutationResult<LearningMaterial>> createMaterial(
  LearningMaterialLocalDataSource localDataSource,
  SyncQueue syncQueue,
  LearningMaterialRemoteDataSource remoteDataSource, {
  required String classId,
  required String title,
  String? description,
  String? contentText,
}) async {
  try {
    final materialId = const Uuid().v4();
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final optimisticModel = LearningMaterialModel(
      id: materialId,
      classId: classId,
      title: title,
      description: description,
      contentText: contentText,
      orderIndex: 0,
      fileCount: 0,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.saveMaterial(optimisticModel, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.create,
          payload: {
            'id': materialId,
            'class_id': classId,
            'title': title,
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
      remote: () => remoteDataSource.createMaterial(
        classId: classId,
        data: {
          'id': materialId,
          'class_id': classId,
          'title': title,
          if (description != null) 'description': description,
          if (contentText != null) 'content_text': contentText,
        },
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverModel) async {
        try {
          final db = await localDataSource.localDatabase.database;

          if (serverModel.id != materialId) {
            await db.update(
              DbTables.learningMaterials,
              {CommonCols.id: serverModel.id},
              where: '${CommonCols.id} = ?',
              whereArgs: [materialId],
            );
            await db.update(
              DbTables.materialFiles,
              {MaterialFilesCols.materialId: serverModel.id},
              where: '${MaterialFilesCols.materialId} = ?',
              whereArgs: [materialId],
            );
          }

          await db.update(
            DbTables.learningMaterials,
            {CommonCols.syncStatus: SyncStatus.synced.dbValue},
            where: '${CommonCols.id} = ?',
            whereArgs: [serverModel.id],
          );
          await syncQueue.markSucceeded(queueEntryId);
        } catch (e) {
          // Ignore database_closed errors in fire-and-forget callbacks
          if (!e.toString().contains('database_closed')) {
            rethrow;
          }
        }
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }

        try {
          final db = await localDataSource.localDatabase.database;
          await db.update(
            DbTables.learningMaterials,
            {CommonCols.syncStatus: SyncStatus.failed.dbValue},
            where: '${CommonCols.id} = ?',
            whereArgs: [materialId],
          );
          await syncQueue.markFailed(queueEntryId, error.toString());
        } catch (e) {
          // Ignore database_closed errors in fire-and-forget callbacks
          if (!e.toString().contains('database_closed')) {
            rethrow;
          }
        }
      },
    );

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
