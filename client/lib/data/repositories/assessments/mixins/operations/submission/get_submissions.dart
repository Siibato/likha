import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';

ResultFuture<List<SubmissionSummary>> getSubmissions(
  AssessmentRepositoryBase base, {
  required String assessmentId,
}) async {
  try {
    List<SubmissionSummary>? cachedSubmissions;
    try {
      cachedSubmissions = await base.localDataSource.getCachedSubmissions(assessmentId);
      RepoLogger.instance.log('getSubmissions: Loaded ${cachedSubmissions.length} cached submissions for assessment $assessmentId');
    } on CacheException catch (e) {
      RepoLogger.instance.log('getSubmissions: No cached submissions available: $e');
    }

    if (cachedSubmissions != null && cachedSubmissions.isNotEmpty) {
      if (base.serverReachabilityService.isServerReachable) {
        unawaited(_refreshSubmissionsFromNetwork(base, assessmentId));
      }
      return Right(cachedSubmissions);
    }

    if (!base.serverReachabilityService.isServerReachable) {
      return const Left(NetworkFailure('No network connection and no cached submissions'));
    }

    return await _fetchAndCacheSubmissions(base, assessmentId);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

Future<void> _refreshSubmissionsFromNetwork(AssessmentRepositoryBase base, String assessmentId) async {
  try {
    RepoLogger.instance.log('_refreshSubmissionsFromNetwork: START for assessmentId=$assessmentId');
    final result = await base.remoteDataSource.getSubmissions(assessmentId: assessmentId);
    RepoLogger.instance.log('_refreshSubmissionsFromNetwork: fetched ${result.length} summaries from remote');
    await base.localDataSource.cacheSubmissions(assessmentId, result);
    RepoLogger.instance.log('getSubmissions: Background refresh cached ${result.length} submissions');

    RepoLogger.instance.log('_refreshSubmissionsFromNetwork: pre-caching ${result.length} submission details');
    for (final submission in result) {
      unawaited(_backgroundFetchAndCacheSubmissionDetail(base, submission.id));
    }
    RepoLogger.instance.log('_refreshSubmissionsFromNetwork: DONE');
  } catch (e) {
    RepoLogger.instance.log('getSubmissions: Background refresh failed: $e');
  }
}

Future<void> _backgroundFetchAndCacheSubmissionDetail(AssessmentRepositoryBase base, String submissionId) async {
  try {
    RepoLogger.instance.log('_backgroundFetchAndCacheSubmissionDetail: START for $submissionId');
    final detail = await base.remoteDataSource.getSubmissionDetail(submissionId: submissionId);
    RepoLogger.instance.log('_backgroundFetchAndCacheSubmissionDetail: fetched detail with ${detail.answers.length} answers');
    await base.localDataSource.cacheSubmissionDetail(detail);
    RepoLogger.instance.log('_backgroundFetchAndCacheSubmissionDetail: cached OK for $submissionId');
  } catch (e) {
    RepoLogger.instance.log('getSubmissions: Detail pre-cache failed for $submissionId: $e');
  }
}

Future<Either<Failure, List<SubmissionSummary>>> _fetchAndCacheSubmissions(AssessmentRepositoryBase base, String assessmentId) async {
  try {
    RepoLogger.instance.log('_fetchAndCacheSubmissions: START for assessmentId=$assessmentId');
    final result = await base.remoteDataSource.getSubmissions(assessmentId: assessmentId);
    RepoLogger.instance.log('_fetchAndCacheSubmissions: fetched ${result.length} summaries from remote');
    try {
      await base.localDataSource.cacheSubmissions(assessmentId, result);
      RepoLogger.instance.log('getSubmissions: Fetched and cached ${result.length} submissions from network');
    } catch (e) {
      RepoLogger.instance.log('getSubmissions: Caching failed (non-fatal): $e');
    }

    RepoLogger.instance.log('_fetchAndCacheSubmissions: pre-caching ${result.length} submission details');
    for (final submission in result) {
      unawaited(_backgroundFetchAndCacheSubmissionDetail(base, submission.id));
    }
    RepoLogger.instance.log('_fetchAndCacheSubmissions: DONE');
    return Right(result);
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  }
}
