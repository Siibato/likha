import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/services/storage_service.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:likha/core/events/data_event_bus.dart';
import '_helpers.dart' as helpers;

ResultFuture<List<Assignment>> getAssignments(
  ServerReachabilityService serverReachabilityService,
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
      // STEP 1: Get current user ID and role to determine query type
      String? currentUserId;
      String? userRole;
      try {
        currentUserId = await storageService.getUserId();
        userRole = await storageService.getUserRole();
        RepoLogger.instance.log('getAssignments() - got currentUserId: $currentUserId, userRole: $userRole');
      } catch (e) {
        RepoLogger.instance.warn('getAssignments() - could not get user info', e);
      }

      // STEP 1a: Try cache with studentId only for students (per-student enrichment)
      // Teachers use studentId=null to get aggregate counts (Path A)
      final isStudent = userRole == 'student';
      final cachedAssignments = await localDataSource.getCachedAssignments(
        classId,
        publishedOnly: publishedOnly,
        studentId: isStudent ? currentUserId : null,
      );

      // STEP 1b: Assignments from cache (enriched with per-student data if user is a student)
      RepoLogger.instance.log('getAssignments() - loading ${cachedAssignments.length} assignments');
      final assignmentsWithSubmissions = <Assignment>[];
      for (final assignment in cachedAssignments) {
        try {
          // Assignments already have submissionId, submissionStatus, score from cache enrichment
          // Just use them directly
          assignmentsWithSubmissions.add(assignment);
        } catch (e) {
          RepoLogger.instance.warn('getAssignments() - error processing ${assignment.title}', e);
          assignmentsWithSubmissions.add(assignment);
        }
      }

      // STEP 2: If cache hit, trigger background fetch to check for updates
      if (!skipBackgroundRefresh) {
        helpers.backgroundFetchAssignments(localDataSource, remoteDataSource, dataEventBus, classId, publishedOnly: publishedOnly);
      }

      // STEP 3: Return cache immediately (don't wait for remote)
      return Right(assignmentsWithSubmissions);
    } on CacheException {
      // Cache miss: return empty immediately, trigger background fetch to populate cache
      // Don't block on remote fetch — offline-first means immediate return
      if (!skipBackgroundRefresh) {
        helpers.backgroundFetchAssignments(localDataSource, remoteDataSource, dataEventBus, classId, publishedOnly: publishedOnly);
      }

      return const Right([]);
    }
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
