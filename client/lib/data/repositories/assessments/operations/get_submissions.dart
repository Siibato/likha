import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultFuture<List<SubmissionSummary>> getSubmissions(
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String assessmentId,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedSubmissions(assessmentId);
      RepoLogger.instance.log('getSubmissions: Loaded ${cached.length} cached submissions for assessment $assessmentId');

      fireRemoteFetch(
        dedupKey: 'assessments/submissions/$assessmentId/bg',
        remote: () => remoteDataSource.getSubmissions(assessmentId: assessmentId),
        onSuccess: (fresh) async {
          try {
            await localDataSource.cacheSubmissions(assessmentId, fresh);
            RepoLogger.instance.log('getSubmissions: Background refresh cached ${fresh.length} submissions');

            // Pre-cache submission details
            for (final submission in fresh) {
              try {
                final detail = await remoteDataSource.getSubmissionDetail(submissionId: submission.id);
                await localDataSource.cacheSubmissionDetail(detail);
              } catch (e) {
                RepoLogger.instance.log('getSubmissions: Detail pre-cache failed for ${submission.id}: $e');
              }
            }
            dataEventBus.notifyAssessmentDetailChanged(assessmentId);
          } catch (e) {
            RepoLogger.instance.log('getSubmissions: Background refresh failed: $e');
          }
        },
      );

      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'assessments/submissions/$assessmentId',
        remote: () => remoteDataSource.getSubmissions(assessmentId: assessmentId),
      );
      try {
        await localDataSource.cacheSubmissions(assessmentId, fresh);
      } catch (e) {
        RepoLogger.instance.log('getSubmissions: Caching failed (non-fatal): $e');
      }

      for (final submission in fresh) {
        try {
          final detail = await remoteDataSource.getSubmissionDetail(submissionId: submission.id);
          await localDataSource.cacheSubmissionDetail(detail);
        } catch (e) {
          RepoLogger.instance.log('getSubmissions: Detail pre-cache failed for ${submission.id}: $e');
        }
      }

      return Right(fresh);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
