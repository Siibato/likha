import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/services/storage_service.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:likha/core/events/data_event_bus.dart';
import '_helpers.dart' as helpers;

ResultFuture<List<Assignment>> getAssignments(
  AssignmentLocalDataSource localDataSource,
  AssignmentRemoteDataSource remoteDataSource,
  StorageService storageService,
  DataEventBus dataEventBus, {
  required String classId,
  bool publishedOnly = false,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      String? currentUserId;
      String? userRole;
      try {
        currentUserId = await storageService.getUserId();
        userRole = await storageService.getUserRole();
        RepoLogger.instance.log('getAssignments() - got currentUserId: $currentUserId, userRole: $userRole');
      } catch (e) {
        RepoLogger.instance.warn('getAssignments() - could not get user info', e);
      }

      final isStudent = userRole == 'student';
      final cachedAssignments = await localDataSource.getCachedAssignments(
        classId,
        publishedOnly: publishedOnly,
        studentId: isStudent ? currentUserId : null,
      );

      RepoLogger.instance.log('getAssignments() - loading ${cachedAssignments.length} assignments');
      final assignmentsWithSubmissions = <Assignment>[];
      for (final assignment in cachedAssignments) {
        try {
          assignmentsWithSubmissions.add(assignment);
        } catch (e) {
          RepoLogger.instance.warn('getAssignments() - error processing ${assignment.title}', e);
          assignmentsWithSubmissions.add(assignment);
        }
      }

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'assignments/$classId/bg',
          remote: () => remoteDataSource.getAssignments(classId: classId),
          onSuccess: (fresh) async {
            final List<Assignment> current;
            try {
              current = await localDataSource.getCachedAssignments(classId, publishedOnly: publishedOnly);
            } on CacheException {
              await localDataSource.cacheAssignments(fresh);
              dataEventBus.notifyAssignmentsChanged(classId);
              return;
            }
            if (helpers.assignmentsHaveChanged(current, fresh)) {
              await localDataSource.cacheAssignments(fresh);
              dataEventBus.notifyAssignmentsChanged(classId);
            }
          },
        );
      }

      return Right(assignmentsWithSubmissions);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'assignments/$classId',
        remote: () => remoteDataSource.getAssignments(classId: classId),
      );
      await localDataSource.cacheAssignments(fresh);
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
