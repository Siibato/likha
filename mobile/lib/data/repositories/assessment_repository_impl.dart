import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/data/datasources/local/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessment_remote_datasource.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';
import 'package:uuid/uuid.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentRemoteDataSource _remoteDataSource;
  final AssessmentLocalDataSource _localDataSource;
  final ValidationService _validationService;
  final ConnectivityService _connectivityService;
  final SyncQueue _syncQueue;

  AssessmentRepositoryImpl({
    required AssessmentRemoteDataSource remoteDataSource,
    required AssessmentLocalDataSource localDataSource,
    required ValidationService validationService,
    required ConnectivityService connectivityService,
    required SyncQueue syncQueue,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _validationService = validationService,
        _connectivityService = connectivityService,
        _syncQueue = syncQueue;

  @override
  ResultFuture<Assessment> createAssessment({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
  }) async {
    try {
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.create,
          payload: {
            'class_id': classId,
            'title': title,
            if (description != null) 'description': description,
            'time_limit_minutes': timeLimitMinutes,
            'open_at': openAt,
            'close_at': closeAt,
            if (showResultsImmediately != null)
              'show_results_immediately': showResultsImmediately,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        // Return optimistic response
        return Right(Assessment(
          id: '',
          classId: classId,
          title: title,
          description: description,
          timeLimitMinutes: timeLimitMinutes,
          openAt: DateTime.parse(openAt),
          closeAt: DateTime.parse(closeAt),
          showResultsImmediately: showResultsImmediately ?? false,
          resultsReleased: false,
          isPublished: false,
          totalPoints: 0,
          questionCount: 0,
          submissionCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      // Online: send to server
      final result = await _remoteDataSource.createAssessment(
        classId: classId,
        data: {
          'title': title,
          if (description != null) 'description': description,
          'time_limit_minutes': timeLimitMinutes,
          'open_at': openAt,
          'close_at': closeAt,
          if (showResultsImmediately != null)
            'show_results_immediately': showResultsImmediately,
        },
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
  ResultFuture<List<Assessment>> getAssessments({
    required String classId,
  }) async {
    try {
      final cached = await _localDataSource.getCachedAssessments(classId);
      unawaited(_validationService.syncAssessments(classId));
      return Right(cached);
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
      // Always try to fetch fresh assessment details for real-time updates
      try {
        final fresh = await _remoteDataSource.getAssessmentDetail(assessmentId: assessmentId);
        await _localDataSource.cacheAssessmentDetail(fresh.assessment, fresh.questions);
        return Right((fresh.assessment, fresh.questions));
      } on NetworkException {
        // Network unavailable, fall back to cache
        try {
          final cached = await _localDataSource.getCachedAssessmentDetail(assessmentId);
          return Right(cached);
        } on CacheException catch (e) {
          return Left(CacheFailure(e.message));
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

  @override
  ResultFuture<Assessment> updateAssessment({
    required String assessmentId,
    String? title,
    String? description,
    int? timeLimitMinutes,
    String? openAt,
    String? closeAt,
    bool? showResultsImmediately,
  }) async {
    try {
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.update,
          payload: {
            'id': assessmentId,
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (timeLimitMinutes != null) 'time_limit_minutes': timeLimitMinutes,
            if (openAt != null) 'open_at': openAt,
            if (closeAt != null) 'close_at': closeAt,
            if (showResultsImmediately != null)
              'show_results_immediately': showResultsImmediately,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        return Right(Assessment(
          id: assessmentId,
          classId: '',
          title: title ?? '',
          description: description,
          timeLimitMinutes: timeLimitMinutes ?? 0,
          openAt: openAt != null ? DateTime.parse(openAt) : DateTime.now(),
          closeAt: closeAt != null ? DateTime.parse(closeAt) : DateTime.now(),
          showResultsImmediately: showResultsImmediately ?? false,
          resultsReleased: false,
          isPublished: false,
          totalPoints: 0,
          questionCount: 0,
          submissionCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (timeLimitMinutes != null) {
        data['time_limit_minutes'] = timeLimitMinutes;
      }
      if (openAt != null) data['open_at'] = openAt;
      if (closeAt != null) data['close_at'] = closeAt;
      if (showResultsImmediately != null) {
        data['show_results_immediately'] = showResultsImmediately;
      }

      final result = await _remoteDataSource.updateAssessment(
        assessmentId: assessmentId,
        data: data,
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
  ResultVoid deleteAssessment({required String assessmentId}) async {
    try {
      await _remoteDataSource.deleteAssessment(assessmentId: assessmentId);
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
  ResultFuture<Assessment> publishAssessment({
    required String assessmentId,
  }) async {
    try {
      final result = await _remoteDataSource.publishAssessment(
        assessmentId: assessmentId,
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
  ResultFuture<Assessment> releaseResults({
    required String assessmentId,
  }) async {
    try {
      final result = await _remoteDataSource.releaseResults(
        assessmentId: assessmentId,
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
  ResultFuture<List<Question>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      final result = await _remoteDataSource.addQuestions(
        assessmentId: assessmentId,
        questions: questions,
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
  ResultFuture<Question> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final result = await _remoteDataSource.updateQuestion(
        questionId: questionId,
        data: data,
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
  ResultVoid deleteQuestion({required String questionId}) async {
    try {
      await _remoteDataSource.deleteQuestion(questionId: questionId);
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
  ResultFuture<List<SubmissionSummary>> getSubmissions({
    required String assessmentId,
  }) async {
    try {
      final result = await _remoteDataSource.getSubmissions(
        assessmentId: assessmentId,
      );
      unawaited(_validationService.validateAndSync('assessments'));
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
  ResultFuture<SubmissionDetail> getSubmissionDetail({
    required String submissionId,
  }) async {
    try {
      final cached = await _localDataSource.getCachedSubmissionDetail(submissionId);
      if (cached != null) {
        unawaited(_validationService.validateAndSync('assessments'));
        return Right(cached);
      }
    } catch (_) {
      // No cached data, fall through to network
    }

    try {
      final result = await _remoteDataSource.getSubmissionDetail(
        submissionId: submissionId,
      );
      unawaited(_localDataSource.cacheSubmissionDetail(result));
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
      final result = await _remoteDataSource.overrideAnswer(
        answerId: answerId,
        isCorrect: isCorrect,
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
  ResultFuture<AssessmentStatistics> getStatistics({
    required String assessmentId,
  }) async {
    try {
      final result = await _remoteDataSource.getStatistics(
        assessmentId: assessmentId,
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
  ResultFuture<StartSubmissionResult> startAssessment({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  }) async {
    try {
      if (!_connectivityService.isOnline) {
        // Offline: load cached questions and create local submission
        try {
          final (_, questions) = await _localDataSource.getCachedAssessmentDetail(assessmentId);
          final localId = await _localDataSource.startAssessmentLocally(
            assessmentId:    assessmentId,
            studentId:       studentId,
            studentName:     studentName,
            studentUsername: studentUsername,
          );
          return Right(StartSubmissionResult(
            submissionId: localId,
            startedAt:    DateTime.now(),
            questions:    questions,
          ));
        } on CacheException catch (e) {
          return Left(CacheFailure('Assessment not available offline: ${e.message}'));
        }
      }

      final result = await _remoteDataSource.startAssessment(
        assessmentId: assessmentId,
      );

      // Cache the result so student can resume offline
      await _localDataSource.cacheStartSubmissionResult(
        submissionId:    result.submissionId,
        assessmentId:    assessmentId,
        studentId:       studentId,
        studentName:     studentName,
        studentUsername: studentUsername,
        startedAt:       result.startedAt,
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
      if (!_connectivityService.isOnline) {
        await _localDataSource.saveAnswersLocally(
          submissionId: submissionId,
          answersJson:  jsonEncode(answers),
        );
        return const Right(null);
      }

      await _remoteDataSource.saveAnswers(
        submissionId: submissionId,
        answers: answers,
      );
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
      if (!_connectivityService.isOnline) {
        // Retrieve assessmentId from local submission record
        final cached = await _localDataSource.getCachedSubmissionDetail(submissionId);
        final assessmentId = cached?.assessmentId ?? '';

        await _localDataSource.submitAssessmentLocally(
          submissionId: submissionId,
          assessmentId: assessmentId,
        );

        return Right(SubmissionSummary(
          id:              submissionId,
          studentId:       cached?.studentId ?? '',
          studentName:     cached?.studentName ?? '',
          studentUsername: '',
          startedAt:       cached?.startedAt ?? DateTime.now(),
          autoScore:       (cached?.autoScore ?? 0.0),
          finalScore:      (cached?.finalScore ?? 0.0),
          isSubmitted:     true,
        ));
      }

      final result = await _remoteDataSource.submitAssessment(
        submissionId: submissionId,
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
  ResultFuture<StudentResult> getStudentResults({
    required String submissionId,
  }) async {
    try {
      final result = await _remoteDataSource.getStudentResults(
        submissionId: submissionId,
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
}
