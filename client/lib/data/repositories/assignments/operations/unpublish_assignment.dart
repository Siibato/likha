import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';

ResultFuture<Assignment> unpublishAssignment(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String assignmentId,
}) async {
  try {
    await localDataSource.markAssignmentUnpublished(assignmentId: assignmentId);

    if (!serverReachabilityService.isServerReachable) {
      final cached = await localDataSource.getCachedAssignmentDetail(assignmentId);
      return Right(cached);
    }

    try {
      final result = await remoteDataSource.unpublishAssignment(
        assignmentId: assignmentId,
      );
      await localDataSource.cacheAssignments([result]);
      return Right(result);
    } on NetworkException {
      final cached = await localDataSource.getCachedAssignmentDetail(assignmentId);
      return Right(cached);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
