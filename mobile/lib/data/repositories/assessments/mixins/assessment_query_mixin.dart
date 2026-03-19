import 'package:dartz/dartz.dart';

import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:uuid/uuid.dart';

mixin AssessmentQueryMixin on AssessmentRepositoryBase {
  @override
  ResultFuture<List<Assessment>> getAssessments({
    required String classId,
    bool publishedOnly = false,
    bool skipBackgroundRefresh = false,
  }) async {
    try {
      try {
        // STEP 1: Try cache first (immediate, non-blocking)
        RepoLogger.instance.log('getAssessments() - loading from cache for classId: $classId');
        final cachedAssessments = await localDataSource.getCachedAssessments(classId, publishedOnly: publishedOnly);
        RepoLogger.instance.log('getAssessments() - loaded ${cachedAssessments.length} cached assessments');

        // STEP 1b: Get current student ID for submission state check
        String? currentStudentId;
        try {
          currentStudentId = await storageService.getUserId();
          RepoLogger.instance.log('getAssessments() - got currentStudentId: $currentStudentId');
        } catch (e) {
          RepoLogger.instance.warn('Could not get current student ID', e);
        }

        // STEP 1c: Compute submissionCount dynamically from actual submissions in DB
        RepoLogger.instance.log('getAssessments() - computing dynamic submission counts and isSubmitted flags');
        final assessmentsWithDynamicCounts = <Assessment>[];
        for (final assessment in cachedAssessments) {
          try {
            final actualSubmissionCount = await localDataSource.getCachedSubmissionCount(assessment.id);
            bool? isSubmitted;

            // Check if current student has submitted (if we have their ID)
            if (currentStudentId != null) {
              try {
                isSubmitted = await localDataSource.hasStudentSubmittedAssessment(
                  assessment.id,
                  currentStudentId,
                );
              } catch (e) {
                RepoLogger.instance.warn('Error getting submission status for ${assessment.title}', e);
              }
            }

            RepoLogger.instance.log('${assessment.title}: cached=${assessment.submissionCount}, actual=$actualSubmissionCount, isSubmitted=$isSubmitted');
            if (actualSubmissionCount != assessment.submissionCount || isSubmitted != null) {
              // Create new assessment with updated submissionCount and isSubmitted
              assessmentsWithDynamicCounts.add(Assessment(
                id: assessment.id,
                classId: assessment.classId,
                title: assessment.title,
                description: assessment.description,
                timeLimitMinutes: assessment.timeLimitMinutes,
                openAt: assessment.openAt,
                closeAt: assessment.closeAt,
                showResultsImmediately: assessment.showResultsImmediately,
                resultsReleased: assessment.resultsReleased,
                isPublished: assessment.isPublished,
                orderIndex: assessment.orderIndex,
                totalPoints: assessment.totalPoints,
                questionCount: assessment.questionCount,
                submissionCount: actualSubmissionCount > 0 ? actualSubmissionCount : assessment.submissionCount,
                isSubmitted: isSubmitted,
                createdAt: assessment.createdAt,
                updatedAt: assessment.updatedAt,
              ));
            } else {
              assessmentsWithDynamicCounts.add(assessment);
            }
          } catch (e) {
            RepoLogger.instance.warn('Error getting submission count/status for ${assessment.title}, using cached', e);
            assessmentsWithDynamicCounts.add(assessment);
          }
        }

        // STEP 2: If cache hit, trigger background fetch to check for updates
        if (!skipBackgroundRefresh) {
          _backgroundFetchAssessments(classId, publishedOnly: publishedOnly);
        }

        // STEP 3: Return cache immediately (don't wait for remote)
        return Right(assessmentsWithDynamicCounts);
      } on CacheException {
        // Cache miss: return empty immediately, trigger background fetch to populate cache
        // Don't block on remote fetch — offline-first means immediate return
        if (!skipBackgroundRefresh) {
          _backgroundFetchAssessments(classId, publishedOnly: publishedOnly);
        }

        return const Right([]);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<(Assessment, List<Question>)> getAssessmentDetail({
    required String assessmentId,
  }) async {
    try {
      try {
        final cached =
            await localDataSource.getCachedAssessmentDetail(assessmentId);
        final (assessment, questions) = cached;

        // Log cache hit
        syncLogger.assessmentDetailLoad(assessmentId, cached: true, questionCount: questions.length);

        // If server is reachable and no questions are cached, fetch from server.
        final shouldRefetch = serverReachabilityService.isServerReachable &&
            questions.isEmpty;

        if (!shouldRefetch) {
          syncLogger.assessmentDetailFetch(assessmentId, online: false);
          // Questions are already cached. If online, refresh in background
          // (e.g., to pick up stale choices from delta sync).
          if (serverReachabilityService.isServerReachable &&
              questions.isNotEmpty) {
            _backgroundFetchAssessmentDetail(assessmentId);
          }
          return Right(cached);
        }

        // Fall through to remote fetch below
        syncLogger.assessmentDetailFetch(assessmentId, online: true);
      } on CacheException {
        // Not in local DB — fall through to remote fetch below
        syncLogger.warn('Assessment detail not in cache for $assessmentId, fetching from server');
      }

      // Remote fetch (covers: cache miss OR stale questions)
      try {
        final fresh = await remoteDataSource.getAssessmentDetail(
            assessmentId: assessmentId);
        syncLogger.assessmentDetailResponse(assessmentId, fresh.questions.length);
        await localDataSource.cacheAssessmentDetail(
            fresh.assessment, fresh.questions);
        return Right((fresh.assessment, fresh.questions));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Assessment> publishAssessment({
    required String assessmentId,
  }) async {
    try {
      try {
        final (_, questions) =
            await localDataSource.getCachedAssessmentDetail(assessmentId);
        if (questions.isEmpty) {
          return const Left(ValidationFailure(
              'Assessment must have at least one question to publish'));
        }
      } catch (e) {
        return Left(CacheFailure('Cannot validate assessment: ${e.toString()}'));
      }

      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.publish,
          payload: {'id': assessmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        // Persist published state to local DB immediately
        await localDataSource.markAssessmentPublishedLocally(assessmentId: assessmentId);

        return Right(Assessment(
          id: assessmentId,
          classId: '',
          title: '',
          description: null,
          timeLimitMinutes: 0,
          openAt: DateTime.now(),
          closeAt: DateTime.now(),
          showResultsImmediately: false,
          resultsReleased: false,
          isPublished: true,
          orderIndex: 0,
          totalPoints: 0,
          questionCount: 0,
          submissionCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final result =
          await remoteDataSource.publishAssessment(assessmentId: assessmentId);
      // Fix: persist published state to local DB (mirrors the offline path)
      await localDataSource.markAssessmentPublishedLocally(assessmentId: assessmentId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Assessment> unpublishAssessment({
    required String assessmentId,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await localDataSource.markAssessmentUnpublishedLocally(assessmentId: assessmentId);

        // Build optimistic response from cached assessment
        try {
          final (cached, _) =
              await localDataSource.getCachedAssessmentDetail(assessmentId);
          return Right(Assessment(
            id: cached.id,
            classId: cached.classId,
            title: cached.title,
            description: cached.description,
            timeLimitMinutes: cached.timeLimitMinutes,
            openAt: cached.openAt,
            closeAt: cached.closeAt,
            showResultsImmediately: cached.showResultsImmediately,
            resultsReleased: cached.resultsReleased,
            isPublished: false,
            orderIndex: cached.orderIndex,
            totalPoints: cached.totalPoints,
            questionCount: cached.questionCount,
            submissionCount: cached.submissionCount,
            createdAt: cached.createdAt,
            updatedAt: DateTime.now(),
          ));
        } catch (_) {
          return Right(Assessment(
            id: assessmentId,
            classId: '',
            title: '',
            description: null,
            timeLimitMinutes: 0,
            openAt: DateTime.now(),
            closeAt: DateTime.now(),
            showResultsImmediately: false,
            resultsReleased: false,
            isPublished: false,
            orderIndex: 0,
            totalPoints: 0,
            questionCount: 0,
            submissionCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      final result =
          await remoteDataSource.unpublishAssessment(assessmentId: assessmentId);
      await localDataSource.markAssessmentUnpublishedLocally(assessmentId: assessmentId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Assessment> releaseResults({
    required String assessmentId,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await localDataSource.releaseResultsLocally(assessmentId: assessmentId);
        // Build optimistic response from cached assessment
        try {
          final (cached, _) =
              await localDataSource.getCachedAssessmentDetail(assessmentId);
          return Right(Assessment(
            id: cached.id,
            classId: cached.classId,
            title: cached.title,
            description: cached.description,
            timeLimitMinutes: cached.timeLimitMinutes,
            openAt: cached.openAt,
            closeAt: cached.closeAt,
            showResultsImmediately: cached.showResultsImmediately,
            resultsReleased: true,
            isPublished: cached.isPublished,
            orderIndex: cached.orderIndex,
            totalPoints: cached.totalPoints,
            questionCount: cached.questionCount,
            submissionCount: cached.submissionCount,
            createdAt: cached.createdAt,
            updatedAt: DateTime.now(),
          ));
        } catch (_) {
          return Right(Assessment(
            id: assessmentId,
            classId: '',
            title: '',
            description: null,
            timeLimitMinutes: 0,
            openAt: DateTime.now(),
            closeAt: DateTime.now(),
            showResultsImmediately: false,
            resultsReleased: true,
            isPublished: false,
            orderIndex: 0,
            totalPoints: 0,
            questionCount: 0,
            submissionCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      final result =
          await remoteDataSource.releaseResults(assessmentId: assessmentId);
      // Fix: also cache the updated assessment (results_released = true)
      await localDataSource.cacheAssessments([result]);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Silently fetches fresh assessments for [classId] from the server.
  /// Handles both cache hit (updates if changed) and cache miss (populates cache).
  /// Emits a DataEventBus event so the page can reload from updated cache.
  /// All errors are swallowed — users keep seeing stale cache without error.
  void _backgroundFetchAssessments(String classId, {bool publishedOnly = false}) {
    Future.microtask(() async {
      try {
        RepoLogger.instance.log('_backgroundFetchAssessments() - fetching fresh assessments for classId: $classId');
        final fresh =
            await remoteDataSource.getAssessments(classId: classId);
        RepoLogger.instance.log('_backgroundFetchAssessments() - received ${fresh.length} fresh assessments');

        // Try to read current cache
        final List<Assessment> cached;
        try {
          cached = await localDataSource.getCachedAssessments(classId, publishedOnly: publishedOnly);
          RepoLogger.instance.log('_backgroundFetchAssessments() - cached ${cached.length} assessments found');
        } on CacheException {
          // Cache miss: initial sync may not have completed yet
          // Write fresh data and notify page to reload with populated cache
          RepoLogger.instance.log('_backgroundFetchAssessments() - cache miss, writing fresh data');
          await localDataSource.cacheAssessments(fresh);
          dataEventBus.notifyAssessmentsChanged(classId);
          return;
        }

        // Cache hit: compare and update only if changed
        if (_assessmentsHaveChanged(cached, fresh)) {
          RepoLogger.instance.log('_backgroundFetchAssessments() - assessments changed, updating cache');
          await localDataSource.cacheAssessments(fresh);
          dataEventBus.notifyAssessmentsChanged(classId);
        } else {
          RepoLogger.instance.log('_backgroundFetchAssessments() - no changes detected, skipping cache update');
        }
        // If nothing changed, do nothing (no DB write, no notification)
      } on NetworkException {
        // Network failure during background fetch: silent fail, cache persists
        RepoLogger.instance.warn('_backgroundFetchAssessments() - network error, cache persists');
      } on ServerException {
        // Server error during background fetch: silent fail, cache persists
        RepoLogger.instance.warn('_backgroundFetchAssessments() - server error, cache persists');
      } catch (e) {
        // Other errors — silent fail, stale cache stays
        RepoLogger.instance.error('_backgroundFetchAssessments() - unexpected error, cache persists', e);
      }
    });
  }

  /// Silently fetches fresh assessment detail from the server.
  /// Updates local cache only if the assessment or questions have changed.
  /// Emits a DataEventBus event so the page can reload from updated cache.
  /// All errors are swallowed — users keep seeing stale cache without error.
  void _backgroundFetchAssessmentDetail(String assessmentId) {
    Future.microtask(() async {
      try {
        final fresh = await remoteDataSource.getAssessmentDetail(
            assessmentId: assessmentId);

        // Compare with cached data
        late Assessment cachedAssessment;
        late List<Question> cachedQuestions;
        try {
          final result =
              await localDataSource.getCachedAssessmentDetail(assessmentId);
          cachedAssessment = result.$1;
          cachedQuestions = result.$2;
        } on CacheException {
          // Cache was cleared — write fresh anyway
          await localDataSource.cacheAssessmentDetail(
              fresh.assessment, fresh.questions);
          dataEventBus.notifyAssessmentDetailChanged(assessmentId);
          return;
        }

        // Check if questions have changed (different count or different content)
        final changed = _assessmentDetailHasChanged(cachedAssessment, cachedQuestions,
            fresh.assessment, fresh.questions);
        syncLogger.assessmentDetailBackgroundFetch(assessmentId, changed: changed);

        if (changed) {
          await localDataSource.cacheAssessmentDetail(
              fresh.assessment, fresh.questions);
          dataEventBus.notifyAssessmentDetailChanged(assessmentId);
        }
        // If nothing changed, do nothing (no DB write, no notification)
      } catch (e) {
        // Network/server error — silent fail, stale cache stays
        syncLogger.warn('Background fetch failed for $assessmentId', e);
      }
    });
  }

  /// Returns true if the assessment or questions have changed.
  bool _assessmentDetailHasChanged(
    Assessment cachedAssessment,
    List<Question> cachedQuestions,
    Assessment remoteAssessment,
    List<Question> remoteQuestions,
  ) {
    // Check if assessment itself changed
    if (cachedAssessment.updatedAt.isBefore(remoteAssessment.updatedAt)) {
      return true;
    }

    // Check if question count differs
    if (cachedQuestions.length != remoteQuestions.length) {
      return true;
    }

    // Check if any question is missing (new question added)
    final cachedIds = {for (final q in cachedQuestions) q.id};
    for (final rq in remoteQuestions) {
      if (!cachedIds.contains(rq.id)) {
        return true; // New question added
      }
    }

    return false;
  }

  /// Returns true if any remote assessment is newer than its local counterpart,
  /// or if the item counts differ (addition or deletion).
  bool _assessmentsHaveChanged(
    List<Assessment> local,
    List<Assessment> remote,
  ) {
    if (local.length != remote.length) return true;
    final localById = {for (final a in local) a.id: a};
    for (final r in remote) {
      final l = localById[r.id];
      if (l == null) return true;                           // New item
      if (l.updatedAt.isBefore(r.updatedAt)) return true;  // Updated item
      if (l.submissionCount != r.submissionCount) return true;  // Submission count changed (students submitted)
    }
    return false;
  }
}