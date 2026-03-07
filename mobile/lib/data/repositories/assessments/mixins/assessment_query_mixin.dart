import 'package:dartz/dartz.dart';
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
  }) async {
    try {
      try {
        final cachedAssessments = await localDataSource.getCachedAssessments(classId, publishedOnly: publishedOnly);

        // If server is reachable, fetch fresh in background (fire-and-forget)
        if (serverReachabilityService.isServerReachable) {
          _backgroundFetchAssessments(classId, publishedOnly: publishedOnly);
        }

        return Right(cachedAssessments);
      } on CacheException {
        // Cache empty — must fetch from server
        try {
          final freshAssessments =
              await remoteDataSource.getAssessments(classId: classId);
          await localDataSource.cacheAssessments(freshAssessments);
          return Right(freshAssessments);
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
          return Left(ValidationFailure(
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
          totalPoints: 0,
          questionCount: 0,
          submissionCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final result =
          await remoteDataSource.publishAssessment(assessmentId: assessmentId);
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
  /// Updates local cache only if any record has a newer [updatedAt].
  /// Emits a DataEventBus event so the page can reload from updated cache.
  /// All errors are swallowed — users keep seeing stale cache without error.
  void _backgroundFetchAssessments(String classId, {bool publishedOnly = false}) {
    Future.microtask(() async {
      try {
        final fresh =
            await remoteDataSource.getAssessments(classId: classId);

        // Compare with cached data using updatedAt timestamps
        final List<Assessment> cached;
        try {
          cached = await localDataSource.getCachedAssessments(classId, publishedOnly: publishedOnly);
        } on CacheException {
          // Cache was cleared between the original read and now — write fresh anyway
          await localDataSource.cacheAssessments(fresh);
          dataEventBus.notifyAssessmentsChanged(classId);
          return;
        }

        if (_assessmentsHaveChanged(cached, fresh)) {
          await localDataSource.cacheAssessments(fresh);
          dataEventBus.notifyAssessmentsChanged(classId);
        }
        // If nothing changed, do nothing (no DB write, no notification)
      } catch (_) {
        // Network/server error — silent fail, stale cache stays
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
    }
    return false;
  }
}