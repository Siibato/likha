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

bool _submissionsHaveChanged(List<SubmissionSummary> current, List<SubmissionSummary> fresh) {
  if (current.length != fresh.length) return true;
  final currentById = {for (final s in current) s.id: s};
  for (final f in fresh) {
    final c = currentById[f.id];
    if (c == null ||
        c.isSubmitted != f.isSubmitted ||
        c.autoScore != f.autoScore ||
        c.finalScore != f.finalScore ||
        c.submittedAt != f.submittedAt) {
      return true;
    }
  }
  return false;
}

ResultFuture<List<SubmissionSummary>> getSubmissions(
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String assessmentId,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedSubmissions(assessmentId);
      RepoLogger.instance.log('getSubmissions: Loaded ${cached.length} cached submissions for assessment $assessmentId');

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'assessments/submissions/$assessmentId/bg',
          remote: () => remoteDataSource.getSubmissions(assessmentId: assessmentId),
          onSuccess: (fresh) async {
            try {
              final current = await localDataSource.getCachedSubmissions(assessmentId);
              if (_submissionsHaveChanged(current, fresh)) {
                await localDataSource.cacheSubmissions(assessmentId, fresh);
                RepoLogger.instance.log('getSubmissions: Background refresh cached ${fresh.length} submissions');
                dataEventBus.notifyAssessmentDetailChanged(assessmentId);
              }
            } on CacheException {
              await localDataSource.cacheSubmissions(assessmentId, fresh);
              RepoLogger.instance.log('getSubmissions: Background refresh cached ${fresh.length} submissions');
              dataEventBus.notifyAssessmentDetailChanged(assessmentId);
            } catch (e) {
              RepoLogger.instance.log('getSubmissions: Background refresh failed: $e');
            }
          },
        );
      }

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
