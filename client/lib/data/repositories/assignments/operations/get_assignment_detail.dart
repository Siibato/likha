import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:likha/core/network/server_reachability_service.dart';

ResultFuture<Assignment> getAssignmentDetail(
  ServerReachabilityService serverReachabilityService,
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource, {
  required String assignmentId,
}) async {
  try {
    try {
      final cached =
          await localDataSource.getCachedAssignmentDetail(assignmentId);
      return Right(cached);
    } on CacheException {
      try {
        final fresh = await remoteDataSource.getAssignmentDetail(
            assignmentId: assignmentId);
        await localDataSource.cacheAssignmentDetail(fresh);
        return Right(fresh);
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      }
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
