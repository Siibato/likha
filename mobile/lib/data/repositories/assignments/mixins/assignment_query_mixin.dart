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
      try {
        final cachedAssignments =
            await localDataSource.getCachedAssignments(classId);

        // If server is reachable, fetch fresh in background (fire-and-forget)
        if (serverReachabilityService.isServerReachable) {
          _backgroundFetchAssignments(classId);
        }

        return Right(cachedAssignments);
      } on CacheException {
        // Cache empty — must fetch from server
        try {
          final freshAssignments =
              await remoteDataSource.getAssignments(classId: classId);
          await localDataSource.cacheAssignments(freshAssignments);
          return Right(freshAssignments);
        } on NetworkException catch (e) {
          return Left(NetworkFailure(e.message));
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        }
      }
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
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Silently fetches fresh assignments for [classId] from the server.
  /// Updates local cache only if any record has a newer [updatedAt].
  /// Emits a DataEventBus event so the page can reload from updated cache.
  /// All errors are swallowed — users keep seeing stale cache without error.
  void _backgroundFetchAssignments(String classId) {
    Future.microtask(() async {
      try {
        final fresh = await remoteDataSource.getAssignments(classId: classId);
        final List<Assignment> cached;
        try {
          cached = await localDataSource.getCachedAssignments(classId);
        } on CacheException {
          await localDataSource.cacheAssignments(fresh);
          dataEventBus.notifyAssignmentsChanged(classId);
          return;
        }
        if (_assignmentsHaveChanged(cached, fresh)) {
          await localDataSource.cacheAssignments(fresh);
          dataEventBus.notifyAssignmentsChanged(classId);
        }
      } catch (_) {}
    });
  }

  bool _assignmentsHaveChanged(List<Assignment> local, List<Assignment> remote) {
    if (local.length != remote.length) return true;
    final localById = {for (final a in local) a.id: a};
    for (final r in remote) {
      final l = localById[r.id];
      if (l == null) return true;
      if (l.updatedAt.isBefore(r.updatedAt)) return true;
    }
    return false;
  }
}