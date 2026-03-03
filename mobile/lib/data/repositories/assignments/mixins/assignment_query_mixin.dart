import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/data/repositories/assignments/assignment_repository_base.dart';

mixin AssignmentQueryMixin on AssignmentRepositoryBase {
  @override
  ResultFuture<List<Assignment>> getAssignments({
    required String classId,
  }) async {
    try {
      var cachedAssignments = <Assignment>[];
      bool hasCachedData = false;

      try {
        cachedAssignments =
            await localDataSource.getCachedAssignments(classId);
        hasCachedData = true;
      } on CacheException {
        hasCachedData = false;
      }

      if (serverReachabilityService.isServerReachable) {
        try {
          final freshAssignments =
              await remoteDataSource.getAssignments(classId: classId);
          await localDataSource.cacheAssignments(freshAssignments);
          return Right(freshAssignments);
        } catch (e) {
          if (!hasCachedData) {
            if (e is ServerException) return Left(ServerFailure(e.message));
            if (e is NetworkException) return Left(NetworkFailure(e.message));
            return Left(ServerFailure(e.toString()));
          }
        }
      }

      if (hasCachedData) return Right(cachedAssignments);
      return Left(NetworkFailure('No internet connection and no cached data'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Assignment> getAssignmentDetail({
    required String assignmentId,
  }) async {
    try {
      try {
        final fresh = await remoteDataSource.getAssignmentDetail(
            assignmentId: assignmentId);
        await localDataSource.cacheAssignmentDetail(fresh);
        return Right(fresh);
      } on NetworkException {
        try {
          final cached =
              await localDataSource.getCachedAssignmentDetail(assignmentId);
          return Right(cached);
        } on CacheException catch (e) {
          return Left(CacheFailure(e.message));
        }
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}