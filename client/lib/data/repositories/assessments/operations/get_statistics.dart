import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';

bool _statisticsHaveChanged(
  AssessmentStatisticsModel? local,
  AssessmentStatisticsModel remote,
) {
  if (local == null) return true;
  return jsonEncode(local.toJson()) != jsonEncode(remote.toJson());
}

ResultFuture<AssessmentStatistics> getStatistics(
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String assessmentId,
}) async {
  try {
    // 1. Check cache table first (server-computed stats)
    final cached = await localDataSource.getCachedStatistics(assessmentId);
    if (cached != null) {
      // Background refresh from remote if data may have changed
      fireRemoteFetch(
        dedupKey: 'assessments/statistics/$assessmentId/bg',
        remote: () => remoteDataSource.getStatistics(assessmentId: assessmentId),
        onSuccess: (fresh) async {
          if (_statisticsHaveChanged(cached, fresh)) {
            await localDataSource.cacheStatistics(fresh);
            dataEventBus.notifyStatisticsChanged(assessmentId);
          }
        },
      );
      return Right(cached);
    }

    // 2. Compute locally from SQLite submissions/answers
    final local = await localDataSource.computeStatistics(assessmentId);
    if (local != null) {
      // Do NOT cache locally-computed stats; only server data is authoritative.
      // Background refresh from remote
      fireRemoteFetch(
        dedupKey: 'assessments/statistics/$assessmentId/bg',
        remote: () => remoteDataSource.getStatistics(assessmentId: assessmentId),
        onSuccess: (fresh) async {
          if (_statisticsHaveChanged(local, fresh)) {
            await localDataSource.cacheStatistics(fresh);
            dataEventBus.notifyStatisticsChanged(assessmentId);
          }
        },
      );
      return Right(local);
    }

    // 3. Local data is incomplete — fetch from server synchronously
    final fresh = await remoteFetch(
      dedupKey: 'assessments/statistics/$assessmentId',
      remote: () => remoteDataSource.getStatistics(assessmentId: assessmentId),
    );
    await localDataSource.cacheStatistics(fresh);
    return Right(fresh);
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
