import 'package:dartz/dartz.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';

ResultFuture<SubmissionSummary> submitAssessment(
  AssessmentRepositoryBase base, {
  required String submissionId,
}) async {
  RepoLogger.instance.log('submitAssessment() START - submissionId: $submissionId, serverReachable: ${base.serverReachabilityService.isServerReachable}');
  try {
    if (!base.serverReachabilityService.isServerReachable) {
      RepoLogger.instance.log('submitAssessment() - OFFLINE PATH');
      final cached =
          await base.localDataSource.getCachedSubmissionDetail(submissionId);
      final assessmentId = cached?.assessmentId ?? '';

      double totalPoints = 0.0;
      try {
        final (assessment, _) =
            await base.localDataSource.getCachedAssessmentDetail(assessmentId);
        totalPoints = assessment.totalPoints.toDouble();
      } catch (_) {
        totalPoints = 0.0;
      }

      await base.localDataSource.submitAssessmentLocally(
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
        await base.remoteDataSource.submitAssessment(submissionId: submissionId);

    RepoLogger.instance.log('submitAssessment() ONLINE - caching result immediately');

    try {
      final cachedSubmission = await base.localDataSource.getCachedSubmissionDetail(submissionId);
      RepoLogger.instance.log('submitAssessment() - retrieved cachedSubmission: id=${cachedSubmission?.id}, isSubmitted=${cachedSubmission?.isSubmitted}');

      if (cachedSubmission != null) {
        RepoLogger.instance.log('submitAssessment() - about to cache with: isSubmitted=true, submittedAt=${result.submittedAt}');
        final modelToCache = SubmissionDetailModel(
          id: result.id,
          assessmentId: cachedSubmission.assessmentId,
          studentId: result.studentId,
          studentName: result.studentName,
          startedAt: result.startedAt,
          submittedAt: result.submittedAt, // Use server's submission timestamp
          autoScore: result.autoScore,
          finalScore: result.finalScore,
          isSubmitted: true, // Mark as submitted
          totalPoints: result.totalPoints,
          answers: cachedSubmission.answers, // Preserve existing answers
        );

        RepoLogger.instance.log('submitAssessment() - SubmissionDetailModel created: isSubmitted=${modelToCache.isSubmitted}, submittedAt=${modelToCache.submittedAt}');

        await base.localDataSource.cacheSubmissionDetail(modelToCache);

        RepoLogger.instance.log('submitAssessment() - SUCCESSFULLY cached submission with is_submitted=true');
        final verifyCache = await base.localDataSource.getCachedSubmissionDetail(submissionId);
        RepoLogger.instance.log('submitAssessment() - VERIFICATION: cached submission now has isSubmitted=${verifyCache?.isSubmitted}, submittedAt=${verifyCache?.submittedAt}');
      } else {
        RepoLogger.instance.warn('submitAssessment() - cachedSubmission was NULL, cannot cache');
      }
    } catch (e) {
      RepoLogger.instance.error('submitAssessment() ONLINE - EXCEPTION during cache', e);
    }

    try {
      final cached =
          await base.localDataSource.getCachedSubmissionDetail(submissionId);
      if (cached != null) {
        final assessmentDetail = await base.localDataSource
            .getCachedAssessmentDetail(cached.assessmentId);
        if (assessmentDetail.$1.showResultsImmediately == true) {
          RepoLogger.instance.log('submitAssessment() ONLINE - showResultsImmediately=true, fetching student results');
          final studentResults =
              await base.remoteDataSource.getStudentResults(submissionId: submissionId);
          await base.localDataSource.cacheStudentResults(studentResults);
          RepoLogger.instance.log('submitAssessment() ONLINE - cached student results');
        }
      }
    } catch (e) {
      RepoLogger.instance.warn('submitAssessment() ONLINE - failed to cache student results', e);
    }

    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
