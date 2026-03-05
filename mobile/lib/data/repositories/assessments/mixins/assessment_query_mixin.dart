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
  }) async {
    try {
      try {
        final cachedAssessments = await localDataSource.getCachedAssessments(classId);
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

        // If server is reachable and local questions are stale (count says there
        // should be questions but none are cached), fall through to refresh.
        final shouldRefetch = serverReachabilityService.isServerReachable &&
            assessment.questionCount > 0 &&
            questions.isEmpty;

        if (!shouldRefetch) {
          return Right(cached);
        }
        // Fall through to remote fetch below
      } on CacheException {
        // Not in local DB — fall through to remote fetch below
      }

      // Remote fetch (covers: cache miss OR stale questions)
      try {
        final fresh = await remoteDataSource.getAssessmentDetail(
            assessmentId: assessmentId);
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
}