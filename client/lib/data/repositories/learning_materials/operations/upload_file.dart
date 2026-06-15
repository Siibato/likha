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
import 'package:likha/data/models/learning_materials/material_file_model.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:uuid/uuid.dart';
import '_helpers.dart' as helpers;

ResultFuture<MutationResult<MaterialFile>> uploadFile(
  LearningMaterialLocalDataSource localDataSource,
  SyncQueue syncQueue,
  LearningMaterialRemoteDataSource remoteDataSource, {
  required String materialId,
  required String filePath,
  required String fileName,
  void Function(int sent, int total)? onSendProgress,
}) async {
  try {
    final mime = helpers.mimeType(filePath);
    final size = await helpers.fileSize(filePath);
    final now = DateTime.now();
    final fileId = const Uuid().v4();
    final queueEntryId = const Uuid().v4();

    final stagedPath = await localDataSource.stageMaterialFileForUpload(
      materialId: materialId,
      fileName: fileName,
      fileType: mime,
      fileSize: size,
      localPath: filePath,
      fileId: fileId,
    );

    final optimisticModel = MaterialFileModel(
      id: fileId,
      materialId: materialId,
      fileName: fileName,
      fileType: mime,
      fileSize: size,
      uploadedAt: now,
      localPath: stagedPath,
      syncStatus: SyncStatus.pending,
      cachedAt: now,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.saveFile(optimisticModel, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.materialFile,
          operation: SyncOperation.upload,
          payload: {
            'file_id': fileId,
            'material_id': materialId,
            'local_path': stagedPath,
            'file_name': fileName,
            'file_type': mime,
            'file_size': size,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<MaterialFileModel>(
      remote: () => remoteDataSource.uploadFile(
        materialId: materialId,
        filePath: stagedPath,
        fileName: fileName,
        onSendProgress: onSendProgress,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverModel) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.materialFiles,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [fileId],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }

        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.materialFiles,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [fileId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
