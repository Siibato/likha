import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/logging/sync_logger.dart';

ResultFuture<(Assessment, List<Question>)> getAssessmentDetail(
  ServerReachabilityService serverReachabilityService,
AssessmentLocalDataSource localDataSource,
AssessmentRemoteDataSource remoteDataSource,
DataEventBus dataEventBus,
SyncLogger syncLogger, {
  required String assessmentId,
}) async {
  try {
    try {
      final cached =
          await localDataSource.getCachedAssessmentDetail(assessmentId);
      final (assessment, questions) = cached;

      syncLogger.assessmentDetailLoad(assessmentId, cached: true, questionCount: questions.length);

      final shouldRefetch = serverReachabilityService.isServerReachable &&
          questions.isEmpty;

      if (!shouldRefetch) {
        syncLogger.assessmentDetailFetch(assessmentId, online: false);
        if (serverReachabilityService.isServerReachable &&
            questions.isNotEmpty) {
          _backgroundFetchAssessmentDetail(serverReachabilityService, localDataSource, remoteDataSource, dataEventBus, syncLogger, assessmentId);
        }
        return Right(cached);
      }

      syncLogger.assessmentDetailFetch(assessmentId, online: true);
    } on CacheException {
      syncLogger.warn('Assessment detail not in cache for $assessmentId, fetching from server');
    }
    try {
      final fresh = await remoteDataSource.getAssessmentDetail(
          assessmentId: assessmentId);
      syncLogger.assessmentDetailResponse(assessmentId, fresh.questions.length);
      await localDataSource.cacheAssessmentDetail(
          fresh.assessment, fresh.questions);
      return Right((fresh.assessment, fresh.questions));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

void _backgroundFetchAssessmentDetail(
  ServerReachabilityService serverReachabilityService,
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus,
  SyncLogger syncLogger,
  String assessmentId,
) {
  Future.microtask(() async {
    try {
      final fresh = await remoteDataSource.getAssessmentDetail(
          assessmentId: assessmentId);

      late Assessment cachedAssessment;
      late List<Question> cachedQuestions;
      try {
        final result =
            await localDataSource.getCachedAssessmentDetail(assessmentId);
        cachedAssessment = result.$1;
        cachedQuestions = result.$2;
      } on CacheException {
        await localDataSource.cacheAssessmentDetail(
            fresh.assessment, fresh.questions);
        dataEventBus.notifyAssessmentDetailChanged(assessmentId);
        return;
      }

      final changed = _assessmentDetailHasChanged(cachedAssessment, cachedQuestions,
          fresh.assessment, fresh.questions);
      syncLogger.assessmentDetailBackgroundFetch(assessmentId, changed: changed);

      if (changed) {
        await localDataSource.cacheAssessmentDetail(
            fresh.assessment, fresh.questions);
        dataEventBus.notifyAssessmentDetailChanged(assessmentId);
      }
    } catch (e) {
      syncLogger.warn('Background fetch failed for $assessmentId', e);
    }
  });
}

bool _assessmentDetailHasChanged(
  Assessment cachedAssessment,
  List<Question> cachedQuestions,
  Assessment remoteAssessment,
  List<Question> remoteQuestions,
) {
  if (cachedAssessment.updatedAt.isBefore(remoteAssessment.updatedAt)) {
    return true;
  }

  if (cachedQuestions.length != remoteQuestions.length) {
    return true;
  }

  final cachedIds = {for (final q in cachedQuestions) q.id};
  for (final rq in remoteQuestions) {
    if (!cachedIds.contains(rq.id)) {
      return true;
    }
  }

  return false;
}
