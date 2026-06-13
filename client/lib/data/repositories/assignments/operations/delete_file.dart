import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';

ResultVoid deleteFile(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {required String fileId}) async {
  try {
    await localDataSource.softDeleteSubmissionFile(fileId);

    if (!serverReachabilityService.isServerReachable) {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.submissionFile,
        operation: SyncOperation.delete,
        payload: {'file_id': fileId},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));
      return const Right(null);
    }

    try {
      await remoteDataSource.deleteFile(fileId: fileId);
      return const Right(null);
    } on NetworkException {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.submissionFile,
        operation: SyncOperation.delete,
        payload: {'file_id': fileId},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));
      return const Right(null);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
