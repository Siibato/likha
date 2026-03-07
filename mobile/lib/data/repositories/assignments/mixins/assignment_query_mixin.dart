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
        // STEP 1: Try cache first (immediate, non-blocking)
        final cachedAssignments =
            await localDataSource.getCachedAssignments(classId, publishedOnly: publishedOnly);

        // STEP 1b: Get current student ID for submission state check
        String? currentStudentId;
        try {
          currentStudentId = await storageService.getUserId();
          print('📚 [AssignmentQueryMixin] getAssignments() - got currentStudentId: $currentStudentId');
        } catch (e) {
          print('⚠️  [AssignmentQueryMixin] getAssignments() - could not get current student ID: $e');
        }

        // STEP 1c: Populate submissionId and submissionStatus from assignment_submissions table
        print('📚 [AssignmentQueryMixin] getAssignments() - loading ${cachedAssignments.length} assignments');
        final assignmentsWithSubmissions = <Assignment>[];
        for (final assignment in cachedAssignments) {
          try {
            Assignment assignmentWithSubmission = assignment;

            // If we have student ID, look up their submission for this assignment
            if (currentStudentId != null) {
              try {
                final submission = await localDataSource.getStudentSubmissionForAssignment(
                  assignment.id,
                  currentStudentId,
                );

                if (submission != null) {
                  final (submissionId, status, score) = submission;
                  print('📚 [AssignmentQueryMixin]   - ${assignment.title}: submissionId=$submissionId, status=$status, score=$score');
                  // Create new assignment with submission data populated
                  assignmentWithSubmission = Assignment(
                    id: assignment.id,
                    classId: assignment.classId,
                    title: assignment.title,
                    instructions: assignment.instructions,
                    totalPoints: assignment.totalPoints,
                    submissionType: assignment.submissionType,
                    allowedFileTypes: assignment.allowedFileTypes,
                    maxFileSizeMb: assignment.maxFileSizeMb,
                    dueAt: assignment.dueAt,
                    isPublished: assignment.isPublished,
                    submissionCount: assignment.submissionCount,
                    gradedCount: assignment.gradedCount,
                    submissionId: submissionId,
                    submissionStatus: status,
                    score: score ?? assignment.score,
                    createdAt: assignment.createdAt,
                    updatedAt: assignment.updatedAt,
                  );
                } else {
                  print('📚 [AssignmentQueryMixin]   - ${assignment.title}: no submission found');
                }
              } catch (e) {
                print('⚠️  [AssignmentQueryMixin]   - ${assignment.title}: error getting submission: $e');
                // If lookup fails, keep the original assignment without submission data
              }
            }

            assignmentsWithSubmissions.add(assignmentWithSubmission);
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