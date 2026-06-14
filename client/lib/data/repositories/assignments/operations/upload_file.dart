import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import '_helpers.dart' as helpers;

ResultFuture<SubmissionFile> uploadFile(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String submissionId,
  required String filePath,
  required String fileName,
  void Function(int sent, int total)? onSendProgress,
}) async {
  try {
    final size = await helpers.fileSize(filePath);
    final mime = helpers.mimeType(filePath);

    if (!serverReachabilityService.isServerReachable) {
      final localFileId = const Uuid().v4();
      await localDataSource.stageFileForUpload(
        submissionId: submissionId,
        fileName: fileName,
        fileType: mime,
        fileSize: size,
        localPath: filePath,
      );

      return Right(SubmissionFile(
        id: localFileId,
        fileName: fileName,
        fileType: mime,
        fileSize: size,
        uploadedAt: DateTime.now(),
        localPath: filePath,
        syncStatus: SyncStatus.pending,
        cachedAt: DateTime.now(),
      ));
    }

    final tempId = const Uuid().v4();
    final optimisticFile = SubmissionFileModel(
      id: tempId,
      submissionId: submissionId,
      fileName: fileName,
      fileType: mime,
      fileSize: size,
      uploadedAt: DateTime.now(),
      localPath: filePath,
      syncStatus: SyncStatus.pending,
      cachedAt: DateTime.now(),
    );
    await localDataSource.cacheSubmissionFile(submissionId, optimisticFile);

    try {
      final result = await remoteDataSource.uploadFile(
        submissionId: submissionId,
        filePath: filePath,
        fileName: fileName,
        onSendProgress: onSendProgress,
      );
      await localDataSource.softDeleteSubmissionFile(tempId);
      await localDataSource.cacheSubmissionFile(submissionId, result);
      return Right(result);
    } on NetworkException {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.submissionFile,
        operation: SyncOperation.upload,
        payload: {
          'file_id': tempId,
          'submission_id': submissionId,
          'local_path': filePath,
          'file_name': fileName,
          'file_type': mime,
          'file_size': size,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));
      return Right(optimisticFile);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
