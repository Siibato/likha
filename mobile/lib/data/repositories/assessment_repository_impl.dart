import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/services/storage_service.dart';
import 'package:likha/data/datasources/local/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessment_remote_datasource.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';
import 'package:likha/data/models/assessments/question_model.dart' show QuestionModel, ChoiceModel, CorrectAnswerModel, EnumerationItemModel, EnumerationItemAnswerModel;
import 'package:uuid/uuid.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentRemoteDataSource _remoteDataSource;
  final AssessmentLocalDataSource _localDataSource;
  final ValidationService _validationService;
  final SyncQueue _syncQueue;
  final ServerReachabilityService _serverReachabilityService;
  final StorageService _storageService;

  AssessmentRepositoryImpl({
    required AssessmentRemoteDataSource remoteDataSource,
    required AssessmentLocalDataSource localDataSource,
    required ValidationService validationService,
    required ConnectivityService connectivityService,
    required SyncQueue syncQueue,
    required ServerReachabilityService serverReachabilityService,
    required StorageService storageService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _validationService = validationService,
        _syncQueue = syncQueue,
        _serverReachabilityService = serverReachabilityService,
        _storageService = storageService;

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
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: create assessment locally with UUID and queue sync
        final assessmentId = await _localDataSource.createAssessmentLocally(
          classId: classId,
          title: title,
          description: description,
          timeLimitMinutes: timeLimitMinutes,
          openAt: openAt,
          closeAt: closeAt,
          showResultsImmediately: showResultsImmediately,
        );

        // Queue sync operation (CRITICAL: this was missing!)
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

        // Return optimistic response with real UUID
        final now = DateTime.now();
        return Right(Assessment(
          id: assessmentId,
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
          createdAt: now,
          updatedAt: now,
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
      var cachedAssessments = <Assessment>[];
      bool hasCachedData = false;

      // Step 1: Try to get cached data
      try {
        cachedAssessments = await _localDataSource.getCachedAssessments(classId);
        hasCachedData = true;
      } on CacheException {
        hasCachedData = false;
      }

      // Step 2: If online, fetch fresh data
      if (_serverReachabilityService.isServerReachable) {
        try {
          final freshAssessments = await _remoteDataSource.getAssessments(classId: classId);
          await _localDataSource.cacheAssessments(freshAssessments);
          return Right(freshAssessments);
        } catch (e) {
          // Server fetch failed - fall through to cached data
          if (!hasCachedData) {
            if (e is ServerException) {
              return Left(ServerFailure(e.message));
            } else if (e is NetworkException) {
              return Left(NetworkFailure(e.message));
            }
            return Left(ServerFailure(e.toString()));
          }
          // Has cache, will use it below
        }
      }

      // Step 3: Use cached data if we have it
      if (hasCachedData) {
        return Right(cachedAssessments);
      }

      // No cache and no internet
      return Left(NetworkFailure('No internet connection and no cached data'));
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
      if (!_serverReachabilityService.isServerReachable) {
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
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assessment,
            operation: SyncOperation.delete,
            payload: {'id': assessmentId},
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: DateTime.now(),
          ),
        );
        return const Right(null);
      }

      // Online: send to server
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
      // Step 1: Validate assessment has at least 1 question
      // (prevents queuing invalid state for sync)
      try {
        final (_, questions) = await _localDataSource.getCachedAssessmentDetail(assessmentId);

        if (questions.isEmpty) {
          return Left(ValidationFailure('Assessment must have at least one question to publish'));
        }
      } catch (e) {
        return Left(CacheFailure('Cannot validate assessment: ${e.toString()}'));
      }

      // Step 2: Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.publish,
          payload: {
            'id': assessmentId,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        // Return optimistic response
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
          isPublished: true,  // ← Optimistic: mark as published
          totalPoints: 0,
          questionCount: 0,
          submissionCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      // Online: send to server
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
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assessment,
            operation: SyncOperation.releaseResults,
            payload: {'id': assessmentId},
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: DateTime.now(),
          ),
        );

        // Return optimistic response (user sees results as released)
        try {
          final (cached, _) = await _localDataSource.getCachedAssessmentDetail(assessmentId);
          // Reconstruct with resultsReleased flag set
          return Right(Assessment(
            id: cached.id,
            classId: cached.classId,
            title: cached.title,
            description: cached.description,
            timeLimitMinutes: cached.timeLimitMinutes,
            openAt: cached.openAt,
            closeAt: cached.closeAt,
            showResultsImmediately: cached.showResultsImmediately,
            resultsReleased: true,  // ← Optimistic
            isPublished: cached.isPublished,
            totalPoints: cached.totalPoints,
            questionCount: cached.questionCount,
            submissionCount: cached.submissionCount,
            createdAt: cached.createdAt,
            updatedAt: cached.updatedAt,
          ));
        } catch (e) {
          // If no cache available, return generic assessment
          return Right(Assessment(
            id: assessmentId,
            classId: '',
            title: '',
            description: null,
            timeLimitMinutes: 0,
            openAt: DateTime.now(),
            closeAt: DateTime.now(),
            showResultsImmediately: false,
            resultsReleased: true,  // ← Optimistic
            isPublished: false,
            totalPoints: 0,
            questionCount: 0,
            submissionCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      // Online: send to server
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
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: Save questions locally and queue for sync

        // Step 1: Create QuestionModel instances with local UUIDs
        final questionModels = questions.map((q) {
          final id = const Uuid().v4();
          return QuestionModel(
            id: id,
            questionType: q['question_type'] as String,
            questionText: q['question_text'] as String,
            points: q['points'] as int,
            orderIndex: q['order_index'] as int? ?? 0,
            isMultiSelect: q['is_multi_select'] as bool? ?? false,
            choices: (q['choices'] as List?)?.map((c) {
              return ChoiceModel(
                id: const Uuid().v4(),
                choiceText: c['choice_text'] as String,
                isCorrect: c['is_correct'] as bool,
                orderIndex: c['order_index'] as int,
              );
            }).toList(),
            correctAnswers: (q['correct_answers'] as List?)?.map((a) {
              return CorrectAnswerModel(
                id: const Uuid().v4(),
                answerText: a is String ? a : (a as Map)['answer_text'] as String,
              );
            }).toList(),
            enumerationItems: (q['enumeration_items'] as List?)?.map((e) {
              return EnumerationItemModel(
                id: const Uuid().v4(),
                orderIndex: e['order_index'] as int,
                acceptableAnswers: (e['acceptable_answers'] as List?)
                    ?.map((a) => EnumerationItemAnswerModel(
                          id: const Uuid().v4(),
                          answerText: a is String ? a : (a as Map)['answer_text'] as String,
                        ))
                    .toList() ?? const [],
              );
            }).toList(),
          );
        }).toList();

        // Step 2: Cache questions locally
        await _localDataSource.cacheQuestions(questionModels);

        // Step 3: Batch all questions for this assessment in ONE queue entry
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.question,
          operation: SyncOperation.create,
          payload: {
            'assessment_id': assessmentId,
            'questions': questions,  // Full batch of questions
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        // Step 4: Return optimistic response
        return Right(questionModels);
      }

      // Online: send to server
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
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: Update question locally and queue for sync
        await _localDataSource.updateQuestionLocally(
          questionId: questionId,
          updates: data,
        );

        // Queue the operation with full question data
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.question,
          operation: SyncOperation.update,
          payload: {
            'id': questionId,
            ...data,  // Full question data
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        // Return optimistic response
        return Right(Question(
          id: questionId,
          questionType: data['question_type'] as String? ?? '',
          questionText: data['question_text'] as String? ?? '',
          points: data['points'] as int? ?? 0,
          orderIndex: data['order_index'] as int? ?? 0,
          isMultiSelect: data['is_multi_select'] as bool? ?? false,
        ));
      }

      // Online: send to server
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
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: Soft delete locally and queue for sync
        await _localDataSource.deleteQuestionLocally(
          questionId: questionId,
        );

        // Queue the operation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.question,
          operation: SyncOperation.delete,
          payload: {
            'id': questionId,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);
        return const Right(null);
      }

      // Online: send to server
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
      // Try remote first
      try {
        final result = await _remoteDataSource.getSubmissions(
          assessmentId: assessmentId,
        );
        // Cache the result for offline access
        await _localDataSource.cacheSubmissions(assessmentId, result);
        unawaited(_validationService.validateAndSync('assessments'));
        return Right(result);
      } on NetworkException {
        // Network unavailable, fall back to cache
        try {
          final cached = await _localDataSource.getCachedSubmissions(assessmentId);
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
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation (silent, no UI warning)
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.assessmentSubmission,
            operation: SyncOperation.overrideAnswer,
            payload: {
              'answer_id': answerId,
              'is_correct': isCorrect,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: DateTime.now(),
          ),
        );

        // Return optimistic response
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

      // Online: send to server
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
      // Try remote first
      try {
        final result = await _remoteDataSource.getStatistics(
          assessmentId: assessmentId,
        );
        // Cache the result for offline access
        await _localDataSource.cacheStatistics(result);
        return Right(result);
      } on NetworkException {
        // Network unavailable, fall back to cache
        try {
          final cached = await _localDataSource.getCachedStatistics(assessmentId);
          if (cached != null) {
            return Right(cached);
          }
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
      if (!_serverReachabilityService.isServerReachable) {
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
      if (!_serverReachabilityService.isServerReachable) {
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
      if (!_serverReachabilityService.isServerReachable) {
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
      // Try remote first
      try {
        final result = await _remoteDataSource.getStudentResults(
          submissionId: submissionId,
        );
        // Cache the result for offline access
        await _localDataSource.cacheStudentResults(result);
        return Right(result);
      } on NetworkException {
        // Network unavailable, fall back to cache
        try {
          final cached = await _localDataSource.getCachedStudentResults(submissionId);
          if (cached != null) {
            return Right(cached);
          }
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
