import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
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
  Uint8List? fileBytes,
  void Function(int sent, int total)? onSendProgress,
}) async {
  try {
    RepoLogger.instance.log('uploadFile: material_id=${materialId.substring(0, 8)} file=$fileName');

    final mime = helpers.mimeType(fileName);
    final size = fileBytes?.length ?? await helpers.fileSize(filePath);
    final now = DateTime.now();
    final fileId = const Uuid().v4();

    // ------------------------------------------------------------------
    // Web path: direct upload (no filesystem staging on web)
    // ------------------------------------------------------------------
    if (kIsWeb && fileBytes != null) {
      RepoLogger.instance.log('uploadFile: web direct upload file_id=${fileId.substring(0, 8)} mime=$mime size=$size');

      final optimisticModel = MaterialFileModel(
        id: fileId,
        materialId: materialId,
        fileName: fileName,
        fileType: mime,
        fileSize: size,
        uploadedAt: now,
        localPath: '',
        syncStatus: SyncStatus.pending,
        cachedAt: now,
      );

      final db = await localDataSource.localDatabase.database;
      await db.transaction((txn) async {
        await localDataSource.saveFile(optimisticModel, txn: txn);
      });

      RepoLogger.instance.log('uploadFile: web uploading file_id=${fileId.substring(0, 8)}');
      final serverFile = await remoteDataSource.uploadFile(
        materialId: materialId,
        filePath: filePath,
        fileName: fileName,
        fileBytes: fileBytes,
        onSendProgress: onSendProgress,
      );

      // Reconcile server response into local DB
      final reconciledModel = MaterialFileModel(
        id: serverFile.id,
        materialId: materialId,
        fileName: serverFile.fileName,
        fileType: serverFile.fileType,
        fileSize: serverFile.fileSize,
        uploadedAt: serverFile.uploadedAt,
        localPath: '',
        syncStatus: SyncStatus.synced,
        cachedAt: now,
      );
      await localDataSource.saveFile(reconciledModel);

      RepoLogger.instance.log('uploadFile: web upload succeeded file_id=${serverFile.id.substring(0, 8)}');
      return Right(MutationResult(entity: reconciledModel, status: SyncStatus.synced));
    }

    // ------------------------------------------------------------------
    // Native path: stage file + enqueue for sync engine
    // ------------------------------------------------------------------
    final queueEntryId = const Uuid().v4();

    RepoLogger.instance.log('uploadFile: staging file file_id=${fileId.substring(0, 8)} mime=$mime size=$size');

    final stagedPath = await localDataSource.stageMaterialFileForUpload(
      materialId: materialId,
      fileName: fileName,
      fileType: mime,
      fileSize: size,
      localPath: filePath,
      fileId: fileId,
    );

    RepoLogger.instance.log('uploadFile: staged at $stagedPath');

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
      RepoLogger.instance.log('uploadFile: saving file to DB file_id=${fileId.substring(0, 8)}');
      await localDataSource.saveFile(optimisticModel, txn: txn);
      RepoLogger.instance.log('uploadFile: enqueuing sync entry queue_id=${queueEntryId.substring(0, 8)}');
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

    RepoLogger.instance.log('uploadFile: transaction committed, returning optimistic result');
    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    RepoLogger.instance.error('uploadFile: failed - $e');
    return Left(ServerFailure(e.toString()));
  }
}
