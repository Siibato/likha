import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';

mixin AssessmentSubmissionMixin on AssessmentRepositoryBase {
  @override
  ResultFuture<List<SubmissionSummary>> getSubmissions({
    required String assessmentId,
  }) async {
    try {
      try {
        final cached =
            await localDataSource.getCachedSubmissions(assessmentId);
        return Right(cached);
      } on CacheException {
        // Not in local DB — fetch from server if reachable
        try {
          final result =
              await remoteDataSource.getSubmissions(assessmentId: assessmentId);
          await localDataSource.cacheSubmissions(assessmentId, result);
          unawaited(validationService.validateAndSync('assessments'));
          return Right(result);
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
        await localDataSource.overrideAnswerLocally(
          answerId: answerId,
          isCorrect: isCorrect,
        );
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
      // Try cache first
      final cached =
          await localDataSource.getCachedStatistics(assessmentId);
      if (cached != null) return Right(cached);

      // Cache miss — fetch from server if reachable
      try {
        final result =
            await remoteDataSource.getStatistics(assessmentId: assessmentId);
        await localDataSource.cacheStatistics(result);
        return Right(result);
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } catch (e) {
      return Left(CacheFailure('Statistics not available offline'));
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

          // Convert Question domain objects to JSON maps for TakeAssessmentPage
          final questionMaps = questions.map((q) => {
            'id': q.id,
            'question_type': q.questionType,
            'question_text': q.questionText,
            'points': q.points,
            'order_index': q.orderIndex,
            'is_multi_select': q.isMultiSelect,
          }).toList();

          return Right(StartSubmissionResult(
            submissionId: localId,
            startedAt: DateTime.now(),
            questions: questionMaps,
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

      // Best-effort: if showResultsImmediately, fetch and cache student results
      try {
        final cached =
            await localDataSource.getCachedSubmissionDetail(submissionId);
        if (cached != null) {
          final assessmentDetail = await localDataSource
              .getCachedAssessmentDetail(cached.assessmentId);
          if (assessmentDetail.$1.showResultsImmediately == true) {
            final studentResults =
                await remoteDataSource.getStudentResults(submissionId: submissionId);
            await localDataSource.cacheStudentResults(studentResults);
          }
        }
      } catch (_) {
        // Silently fail — don't block submission if result caching fails
      }

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
      // Try cache first
      final cached =
          await localDataSource.getCachedStudentResults(submissionId);
      if (cached != null) return Right(cached);

      // Cache miss — fetch from server if reachable
      try {
        final result = await remoteDataSource.getStudentResults(
            submissionId: submissionId);
        await localDataSource.cacheStudentResults(result);
        return Right(result);
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } catch (e) {
      return Left(const CacheFailure('Student results not available offline'));
    }
  }
}