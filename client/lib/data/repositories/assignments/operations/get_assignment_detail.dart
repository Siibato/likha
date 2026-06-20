import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import '_helpers.dart' as helpers;

ResultFuture<Assignment> getAssignmentDetail(
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String assignmentId,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedAssignmentDetail(assignmentId);

      fireRemoteFetch(
        dedupKey: 'assignments/detail/$assignmentId/bg',
        remote: () => remoteDataSource.getAssignmentDetail(assignmentId: assignmentId),
        onSuccess: (fresh) async {
          final current = await localDataSource.getCachedAssignmentDetail(assignmentId);
          if (helpers.assignmentsHaveChanged([current], [fresh])) {
            await localDataSource.cacheAssignmentDetail(fresh);
            dataEventBus.notifyAssignmentsChanged(fresh.classId);
          }
        },
      );

      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'assignments/detail/$assignmentId',
        remote: () => remoteDataSource.getAssignmentDetail(assignmentId: assignmentId),
      );
      await localDataSource.cacheAssignmentDetail(fresh);
      return Right(fresh);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
