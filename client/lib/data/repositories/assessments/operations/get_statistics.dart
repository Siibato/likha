import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultFuture<AssessmentStatistics> getStatistics(
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String assessmentId,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedStatistics(assessmentId);
      if (cached != null) {
        fireRemoteFetch(
          dedupKey: 'assessments/statistics/$assessmentId/bg',
          remote: () => remoteDataSource.getStatistics(assessmentId: assessmentId),
          onSuccess: (fresh) async {
            final current = await localDataSource.getCachedStatistics(assessmentId);
            if (current == null || current != fresh) {
              await localDataSource.cacheStatistics(fresh);
              dataEventBus.notifyStatisticsChanged(assessmentId);
            }
          },
        );
        return Right(cached);
      }

      final fresh = await remoteFetch(
        dedupKey: 'assessments/statistics/$assessmentId',
        remote: () => remoteDataSource.getStatistics(assessmentId: assessmentId),
      );
      await localDataSource.cacheStatistics(fresh);
      return Right(fresh);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'assessments/statistics/$assessmentId',
        remote: () => remoteDataSource.getStatistics(assessmentId: assessmentId),
      );
      await localDataSource.cacheStatistics(fresh);
      return Right(fresh);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return const Left(CacheFailure('Statistics not available offline'));
  }
}
