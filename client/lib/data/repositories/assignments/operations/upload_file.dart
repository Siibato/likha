import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '_helpers.dart' as helpers;

ResultFuture<MutationResult<SubmissionFile>> uploadFile(
  AssignmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AssignmentRemoteDataSource remoteDataSource, {
  required String submissionId,
  required String filePath,
  required String fileName,
}) async {
  try {
    if (kIsWeb) {
      return const Left(ServerFailure('File upload not supported on web'));
    }

    final size = await helpers.fileSize(filePath);
    final mime = helpers.mimeType(filePath);
    final now = DateTime.now();
    final fileId = const Uuid().v4();
    final queueEntryId = const Uuid().v4();

    final appDir = await getApplicationDocumentsDirectory();
    final uploadDir = Directory('${appDir.path}/offline_uploads');
    if (!await uploadDir.exists()) await uploadDir.create(recursive: true);

    final sourceFile = File(filePath);
    if (!await sourceFile.exists()) {
      return Left(ServerFailure('Source file does not exist: $filePath'));
    }

    final stagedPath = '${uploadDir.path}/${fileId}_$fileName';
    await sourceFile.copy(stagedPath);

    final optimisticFile = SubmissionFileModel(
      id: fileId,
      submissionId: submissionId,
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
      await localDataSource.cacheSubmissionFile(submissionId, optimisticFile, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.submissionFile,
          operation: SyncOperation.upload,
          payload: {
            'file_id': fileId,
            'submission_id': submissionId,
            'local_path': stagedPath,
            'file_name': fileName,
            'file_type': mime,
            'file_size': size,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<SubmissionFileModel>(
      remote: () => remoteDataSource.uploadFile(
        submissionId: submissionId,
        filePath: stagedPath,
        fileName: fileName,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverFile) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.submissionFiles,
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
          DbTables.submissionFiles,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [fileId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: optimisticFile, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
