import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';

mixin AssessmentSubmissionMixin on AssessmentRepositoryBase {
  @override
  ResultFuture<List<SubmissionSummary>> getSubmissions({
    required String assessmentId,
  }) async {
    try {
      // Network-first: always try server for fresh data
      try {
        final result =
            await remoteDataSource.getSubmissions(assessmentId: assessmentId);
        try {
          await localDataSource.cacheSubmissions(assessmentId, result);
        } catch (_) {
          // Non-fatal: caching failed (e.g. FK constraint if students not yet synced)
          // Remote data is still valid — return it
        }
        unawaited(validationService.validateAndSync('assessments'));
        return Right(result);
      } on NetworkException {
        // Offline — fall back to cache
        try {
          final cached =
              await localDataSource.getCachedSubmissions(assessmentId);
          if (cached.isNotEmpty) {
            return Right(cached);
          }
        } on CacheException {
          // No cache available
        }
        return const Left(NetworkFailure('No network connection and no cached submissions'));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
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
      if (cached != null && cached.answers.isNotEmpty) {
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
      return const Left(CacheFailure('Statistics not available offline'));
    }
  }

  @override
  ResultFuture<SubmissionSummary?> getStudentSubmission({
    required String assessmentId,
    required String studentId,
  }) async {
    try {
      final result = await localDataSource.getCachedStudentSubmission(
        assessmentId,
        studentId,
      );
      return Right(result);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
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
      RepoLogger.instance.log('startAssessment() - assessmentId: $assessmentId, studentId: $studentId, serverReachable: ${serverReachabilityService.isServerReachable}');

      if (!serverReachabilityService.isServerReachable) {
        RepoLogger.instance.log('startAssessment() - OFFLINE PATH');
        try {
          // Guard: check for existing in-progress submission before creating a duplicate
          final existingSubmission = await localDataSource.getCachedStudentSubmission(
            assessmentId,
            studentId,
          );
          RepoLogger.instance.log('startAssessment() - existingSubmission: $existingSubmission');

          if (existingSubmission != null && !existingSubmission.isSubmitted) {
            RepoLogger.instance.log('startAssessment() - RESUMING EXISTING SUBMISSION ${existingSubmission.id}');
            // Return the existing submission — resume it, don't create a new one
            final (_, questions) =
                await localDataSource.getCachedAssessmentDetail(assessmentId);
            final questionMaps = questions.map((q) => {
              'id': q.id,
              'question_type': q.questionType,
              'question_text': q.questionText,
              'points': q.points,
              'order_index': q.orderIndex,
              'is_multi_select': q.isMultiSelect,
              if (q.choices != null)
                'choices': q.choices!
                    .map((c) => {
                          'id': c.id,
                          'choice_text': c.choiceText,
                          'order_index': c.orderIndex,
                        })
                    .toList(),
              if (q.enumerationItems != null)
                'enumeration_count': q.enumerationItems!.length,
            }).toList();
            return Right(StartSubmissionResult(
              submissionId: existingSubmission.id,
              startedAt: existingSubmission.startedAt,
              questions: questionMaps,
            ));
          }

          RepoLogger.instance.log('startAssessment() - CREATING NEW OFFLINE SUBMISSION');
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
            if (q.choices != null)
              'choices': q.choices!
                  .map((c) => {
                        'id': c.id,
                        'choice_text': c.choiceText,
                        'order_index': c.orderIndex,
                      })
                  .toList(),
            if (q.enumerationItems != null)
              'enumeration_count': q.enumerationItems!.length,
          }).toList();

          return Right(StartSubmissionResult(
            submissionId: localId,
            startedAt: DateTime.now(),
            questions: questionMaps,
          ));
        } on CacheException catch (e) {
          RepoLogger.instance.error('startAssessment() OFFLINE ERROR', e);
          return Left(
              CacheFailure('Assessment not available offline: ${e.message}'));
        }
      }

      RepoLogger.instance.log('startAssessment() - ONLINE PATH - STARTING');

      // Guard: check for existing in-progress submission before calling server
      final existingSubmission = await localDataSource.getCachedStudentSubmission(
        assessmentId,
        studentId,
      );
      RepoLogger.instance.log('startAssessment() - ONLINE PATH - existingSubmission: $existingSubmission');

      if (existingSubmission != null && !existingSubmission.isSubmitted) {
        RepoLogger.instance.log('startAssessment() - ONLINE PATH - RESUMING EXISTING SUBMISSION ${existingSubmission.id}');
        // Return the existing submission — resume it, don't call server
        final (_, questions) =
            await localDataSource.getCachedAssessmentDetail(assessmentId);
        final questionMaps = questions.map((q) => {
          'id': q.id,
          'question_type': q.questionType,
          'question_text': q.questionText,
          'points': q.points,
          'order_index': q.orderIndex,
          'is_multi_select': q.isMultiSelect,
          if (q.choices != null)
            'choices': q.choices!
                .map((c) => {
                      'id': c.id,
                      'choice_text': c.choiceText,
                      'order_index': c.orderIndex,
                    })
                .toList(),
          if (q.enumerationItems != null)
            'enumeration_count': q.enumerationItems!.length,
        }).toList();
        return Right(StartSubmissionResult(
          submissionId: existingSubmission.id,
          startedAt: existingSubmission.startedAt,
          questions: questionMaps,
        ));
      }

      // ✅ If submission exists AND is submitted, don't hit server
      if (existingSubmission != null && existingSubmission.isSubmitted) {
        RepoLogger.instance.log('startAssessment() - ONLINE PATH - SUBMISSION ALREADY SUBMITTED');
        return const Left(ServerFailure('Assessment already submitted'));
      }

      RepoLogger.instance.log('startAssessment() - ONLINE PATH - NO EXISTING SUBMISSION, CALLING SERVER');
      final result =
          await remoteDataSource.startAssessment(assessmentId: assessmentId);
      RepoLogger.instance.log('startAssessment() - ONLINE SUCCESS - submissionId: ${result.submissionId}');

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
      RepoLogger.instance.error('startAssessment() SERVER ERROR', e);
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      RepoLogger.instance.error('startAssessment() NETWORK ERROR', e);
      return Left(NetworkFailure(e.message));
    } catch (e) {
      RepoLogger.instance.error('startAssessment() UNEXPECTED ERROR', e);
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
    RepoLogger.instance.log('submitAssessment() START - submissionId: $submissionId, serverReachable: ${serverReachabilityService.isServerReachable}');
    try {
      if (!serverReachabilityService.isServerReachable) {
        RepoLogger.instance.log('submitAssessment() - OFFLINE PATH');
        final cached =
            await localDataSource.getCachedSubmissionDetail(submissionId);
        final assessmentId = cached?.assessmentId ?? '';

        // Fetch assessment to get totalPoints (not from finalScore)
        int totalPoints = 0;
        try {
          final (assessment, _) =
              await localDataSource.getCachedAssessmentDetail(assessmentId);
          totalPoints = assessment.totalPoints;
        } catch (_) {
          totalPoints = 0;
        }

        await localDataSource.submitAssessmentLocally(
          submissionId: submissionId,
          assessmentId: assessmentId,
        );

        return Right(SubmissionSummary(
          id: submissionId,
          assessmentId: assessmentId,
          studentId: cached?.studentId ?? '',
          studentName: cached?.studentName ?? '',
          studentUsername: '',
          startedAt: cached?.startedAt ?? DateTime.now(),
          autoScore: cached?.autoScore ?? 0.0,
          finalScore: cached?.finalScore ?? 0.0,
          totalPoints: totalPoints,
          isSubmitted: true,
          needsSync: true,
          submittedAt: DateTime.now(),
          cachedAt: DateTime.now(),
        ));
      }

      final result =
          await remoteDataSource.submitAssessment(submissionId: submissionId);

      RepoLogger.instance.log('submitAssessment() ONLINE - caching result immediately');

      // ✅ Immediately cache the submission with updated is_submitted=true and submitted_at timestamp
      try {
        // Get the assessmentId from cached submission
        final cachedSubmission = await localDataSource.getCachedSubmissionDetail(submissionId);
        RepoLogger.instance.log('submitAssessment() - retrieved cachedSubmission: id=${cachedSubmission?.id}, isSubmitted=${cachedSubmission?.isSubmitted}');

        if (cachedSubmission != null) {
          RepoLogger.instance.log('submitAssessment() - about to cache with: isSubmitted=true, submittedAt=${result.submittedAt}');

          final modelToCache = SubmissionDetailModel(
            id: result.id,
            assessmentId: cachedSubmission.assessmentId,
            studentId: result.studentId,
            studentName: result.studentName,
            startedAt: result.startedAt,
            submittedAt: result.submittedAt, // ← Use server's submission timestamp
            autoScore: result.autoScore,
            finalScore: result.finalScore,
            isSubmitted: true, // ← Mark as submitted
            totalPoints: result.totalPoints,
            answers: cachedSubmission.answers, // ← Preserve existing answers
          );

          RepoLogger.instance.log('submitAssessment() - SubmissionDetailModel created: isSubmitted=${modelToCache.isSubmitted}, submittedAt=${modelToCache.submittedAt}');

          await localDataSource.cacheSubmissionDetail(modelToCache);

          RepoLogger.instance.log('submitAssessment() - SUCCESSFULLY cached submission with is_submitted=true');

          // Verify what was cached
          final verifyCache = await localDataSource.getCachedSubmissionDetail(submissionId);
          RepoLogger.instance.log('submitAssessment() - VERIFICATION: cached submission now has isSubmitted=${verifyCache?.isSubmitted}, submittedAt=${verifyCache?.submittedAt}');
        } else {
          RepoLogger.instance.warn('submitAssessment() - cachedSubmission was NULL, cannot cache');
        }
      } catch (e, st) {
        RepoLogger.instance.error('submitAssessment() ONLINE - EXCEPTION during cache', e);
        // Non-fatal: submission succeeded on server, caching failed
        // Sync will update it later
      }

      // Best-effort: if showResultsImmediately, fetch and cache student results
      try {
        final cached =
            await localDataSource.getCachedSubmissionDetail(submissionId);
        if (cached != null) {
          final assessmentDetail = await localDataSource
              .getCachedAssessmentDetail(cached.assessmentId);
          if (assessmentDetail.$1.showResultsImmediately == true) {
            RepoLogger.instance.log('submitAssessment() ONLINE - showResultsImmediately=true, fetching student results');
            final studentResults =
                await remoteDataSource.getStudentResults(submissionId: submissionId);
            await localDataSource.cacheStudentResults(studentResults);
            RepoLogger.instance.log('submitAssessment() ONLINE - cached student results');
          }
        }
      } catch (e) {
        RepoLogger.instance.warn('submitAssessment() ONLINE - failed to cache student results', e);
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
      return const Left(CacheFailure('Student results not available offline'));
    }
  }
}