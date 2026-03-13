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
    bool publishedOnly = false,
    bool skipBackgroundRefresh = false,
  }) async {
    try {
      try {
        // STEP 1: Get current student ID first
        String? currentStudentId;
        try {
          currentStudentId = await storageService.getUserId();
          print('📚 [AssignmentQueryMixin] getAssignments() - got currentStudentId: $currentStudentId');
        } catch (e) {
          print('⚠️  [AssignmentQueryMixin] getAssignments() - could not get current student ID: $e');
        }

        // STEP 1a: Try cache with studentId for per-student enrichment (E2: populates submission_status/score)
        final cachedAssignments = await localDataSource.getCachedAssignments(
          classId,
          publishedOnly: publishedOnly,
          studentId: currentStudentId,
        );

        // STEP 1b: Assignments from cache are now pre-enriched with per-student data
        print('📚 [AssignmentQueryMixin] getAssignments() - loading ${cachedAssignments.length} assignments (enriched with studentId=$currentStudentId)');
        final assignmentsWithSubmissions = <Assignment>[];
        for (final assignment in cachedAssignments) {
          try {
            // Assignments already have submissionId, submissionStatus, score from cache enrichment
            // Just use them directly
            print('📚 [AssignmentQueryMixin]   - ${assignment.title}: submissionStatus=${assignment.submissionStatus}, score=${assignment.score}, submissionCount=${assignment.submissionCount}, gradedCount=${assignment.gradedCount}');
            assignmentsWithSubmissions.add(assignment);
          } catch (e) {
            print('⚠️  [AssignmentQueryMixin]   - ${assignment.title}: unexpected error: $e');
            assignmentsWithSubmissions.add(assignment);
          }
        }

        // STEP 2: If cache hit, trigger background fetch to check for updates
        if (!skipBackgroundRefresh) {
          _backgroundFetchAssignments(classId, publishedOnly: publishedOnly);
        }

        // STEP 3: Return cache immediately (don't wait for remote)
        return Right(assignmentsWithSubmissions);
      } on CacheException {
        // Cache miss: return empty immediately, trigger background fetch to populate cache
        // Don't block on remote fetch — offline-first means immediate return
        if (!skipBackgroundRefresh) {
          _backgroundFetchAssignments(classId, publishedOnly: publishedOnly);
        }

        return const Right([]);
      }
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
  /// Handles both cache hit (updates if changed) and cache miss (populates cache).
  /// Emits a DataEventBus event so the page can reload from updated cache.
  /// All errors are swallowed — users keep seeing stale cache without error.
  void _backgroundFetchAssignments(String classId, {bool publishedOnly = false}) {
    Future.microtask(() async {
      try {
        final fresh = await remoteDataSource.getAssignments(classId: classId);
        final List<Assignment> cached;
        try {
          cached = await localDataSource.getCachedAssignments(classId, publishedOnly: publishedOnly);
        } on CacheException {
          // Cache miss: initial sync may not have completed yet
          // Write fresh data and notify page to reload with populated cache
          await localDataSource.cacheAssignments(fresh);
          dataEventBus.notifyAssignmentsChanged(classId);
          return;
        }
        // Cache hit: compare and update only if changed
        if (_assignmentsHaveChanged(cached, fresh)) {
          await localDataSource.cacheAssignments(fresh);
          dataEventBus.notifyAssignmentsChanged(classId);
        }
      } on NetworkException {
        // Network failure during background fetch: silent fail, cache persists
      } on ServerException {
        // Server error during background fetch: silent fail, cache persists
      } catch (_) {
        // Other errors — silent fail, stale cache stays
      }
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