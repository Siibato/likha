import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:uuid/uuid.dart';

mixin AssessmentSubmissionMixin on AssessmentRepositoryBase {
  @override
  ResultFuture<List<SubmissionSummary>> getSubmissions({
    required String assessmentId,
  }) async {
    try {
      try {
        final result =
            await remoteDataSource.getSubmissions(assessmentId: assessmentId);
        await localDataSource.cacheSubmissions(assessmentId, result);
        unawaited(validationService.validateAndSync('assessments'));
        return Right(result);
      } on NetworkException {
        try {
          final cached =
              await localDataSource.getCachedSubmissions(assessmentId);
          return Right(cached);
        } on CacheException catch (e) {
          return Left(CacheFailure(e.message));
        }
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<SubmissionDetail> getSubmissionDetail({
    required String submissionId,
  }) async {
    try {
      final cached =
          await localDataSource.getCachedSubmissionDetail(submissionId);
      if (cached != null) {
        unawaited(validationService.validateAndSync('assessments'));
        return Right(cached);
      }
    } catch (_) {}

    try {
      final result = await remoteDataSource.getSubmissionDetail(
          submissionId: submissionId);
      unawaited(localDataSource.cacheSubmissionDetail(result));
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
  ResultFuture<SubmissionAnswer> overrideAnswer({
    required String answerId,
    required bool isCorrect,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.overrideAnswer,
          payload: {'answer_id': answerId, 'is_correct': isCorrect},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        return Right(SubmissionAnswer(
          id: answerId,
          questionId: '',
          questionText: '',
          questionType: '',
          points: 0,
          isOverrideCorrect: isCorrect,
          pointsAwarded: 0,
        ));
      }

      final result = await remoteDataSource.overrideAnswer(
          answerId: answerId, isCorrect: isCorrect);
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
  ResultFuture<AssessmentStatistics> getStatistics({
    required String assessmentId,
  }) async {
    try {
      try {
        final result =
            await remoteDataSource.getStatistics(assessmentId: assessmentId);
        await localDataSource.cacheStatistics(result);
        return Right(result);
      } on NetworkException {
        try {
          final cached =
              await localDataSource.getCachedStatistics(assessmentId);
          if (cached != null) return Right(cached);
          return Left(CacheFailure('Statistics not available offline'));
        } on CacheException catch (e) {
          return Left(CacheFailure(e.message));
        }
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<StartSubmissionResult> startAssessment({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        try {
          final (_, questions) =
              await localDataSource.getCachedAssessmentDetail(assessmentId);
          final localId = await localDataSource.startAssessmentLocally(
            assessmentId: assessmentId,
            studentId: studentId,
            studentName: studentName,
            studentUsername: studentUsername,
          );
          return Right(StartSubmissionResult(
            submissionId: localId,
            startedAt: DateTime.now(),
            questions: questions,
          ));
        } on CacheException catch (e) {
          return Left(
              CacheFailure('Assessment not available offline: ${e.message}'));
        }
      }

      final result =
          await remoteDataSource.startAssessment(assessmentId: assessmentId);

      await localDataSource.cacheStartSubmissionResult(
        submissionId: result.submissionId,
        assessmentId: assessmentId,
        studentId: studentId,
        studentName: studentName,
        studentUsername: studentUsername,
        startedAt: result.startedAt,
      );

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
  ResultVoid saveAnswers({
    required String submissionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await localDataSource.saveAnswersLocally(
          submissionId: submissionId,
          answersJson: jsonEncode(answers),
        );
        return const Right(null);
      }

      await remoteDataSource.saveAnswers(
          submissionId: submissionId, answers: answers);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<SubmissionSummary> submitAssessment({
    required String submissionId,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        final cached =
            await localDataSource.getCachedSubmissionDetail(submissionId);
        final assessmentId = cached?.assessmentId ?? '';

        await localDataSource.submitAssessmentLocally(
          submissionId: submissionId,
          assessmentId: assessmentId,
        );

        return Right(SubmissionSummary(
          id: submissionId,
          studentId: cached?.studentId ?? '',
          studentName: cached?.studentName ?? '',
          studentUsername: '',
          startedAt: cached?.startedAt ?? DateTime.now(),
          autoScore: cached?.autoScore ?? 0.0,
          finalScore: cached?.finalScore ?? 0.0,
          isSubmitted: true,
        ));
      }

      final result =
          await remoteDataSource.submitAssessment(submissionId: submissionId);
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
  ResultFuture<StudentResult> getStudentResults({
    required String submissionId,
  }) async {
    try {
      try {
        final result = await remoteDataSource.getStudentResults(
            submissionId: submissionId);
        await localDataSource.cacheStudentResults(result);
        return Right(result);
      } on NetworkException {
        try {
          final cached =
              await localDataSource.getCachedStudentResults(submissionId);
          if (cached != null) return Right(cached);
          return Left(const CacheFailure('Student results not available offline'));
        } on CacheException catch (e) {
          return Left(CacheFailure(e.message));
        }
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}