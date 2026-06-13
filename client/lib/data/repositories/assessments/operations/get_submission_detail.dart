import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultFuture<SubmissionDetail> getSubmissionDetail(
  ServerReachabilityService serverReachabilityService,
AssessmentLocalDataSource localDataSource,
AssessmentRemoteDataSource remoteDataSource, {
  required String submissionId,
}) async {
  try {
    RepoLogger.instance.log('getSubmissionDetail: START for $submissionId');
    final cached = await localDataSource.getCachedSubmissionDetail(submissionId);
    RepoLogger.instance.log('getSubmissionDetail: cached=${cached != null}, answers=${cached?.answers.length ?? 0}');
    if (cached != null) {
      if (cached.answers.isNotEmpty) {
        if (serverReachabilityService.isServerReachable) {
          unawaited(_backgroundRefreshSubmissionDetail(serverReachabilityService, localDataSource, remoteDataSource, submissionId));
        }
        RepoLogger.instance.log('getSubmissionDetail: returning cached with ${cached.answers.length} answers');
        return Right(cached);
      }
      if (!serverReachabilityService.isServerReachable) {
        RepoLogger.instance.log('getSubmissionDetail: OFFLINE, returning cached metadata without answers');
        return Right(cached);
      }
      RepoLogger.instance.log('getSubmissionDetail: ONLINE but cached answers empty, fetching remote');
      try {
        final result = await remoteDataSource.getSubmissionDetail(submissionId: submissionId);
        RepoLogger.instance.log('getSubmissionDetail: fetched ${result.answers.length} answers from remote');
        unawaited(localDataSource.cacheSubmissionDetail(result));
        return Right(result);
      } catch (_) {
        RepoLogger.instance.log('getSubmissionDetail: remote fetch failed, falling back to cached');
        return Right(cached);
      }
    }
  } catch (e) {
    RepoLogger.instance.log('getSubmissionDetail: cache read error: $e');
  }

  if (!serverReachabilityService.isServerReachable) {
    RepoLogger.instance.log('getSubmissionDetail: OFFLINE and no cache, returning NetworkFailure');
    return const Left(NetworkFailure('Submission not available offline'));
  }

  try {
    RepoLogger.instance.log('getSubmissionDetail: fetching from remote (no cache)');
    final result = await remoteDataSource.getSubmissionDetail(submissionId: submissionId);
    RepoLogger.instance.log('getSubmissionDetail: fetched ${result.answers.length} answers from remote');
    unawaited(localDataSource.cacheSubmissionDetail(result));
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

Future<void> _backgroundRefreshSubmissionDetail(
  ServerReachabilityService serverReachabilityService,
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource,
  String submissionId,
) async {
  try {
    final result = await remoteDataSource.getSubmissionDetail(submissionId: submissionId);
    await localDataSource.cacheSubmissionDetail(result);
  } catch (_) {}
}
