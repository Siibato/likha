import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';

ResultFuture<(Assessment, List<Question>)> getAssessmentDetail(
  AssessmentRepositoryBase base, {
  required String assessmentId,
}) async {
  try {
    try {
      final cached =
          await base.localDataSource.getCachedAssessmentDetail(assessmentId);
      final (assessment, questions) = cached;

      base.syncLogger.assessmentDetailLoad(assessmentId, cached: true, questionCount: questions.length);

      final shouldRefetch = base.serverReachabilityService.isServerReachable &&
          questions.isEmpty;

      if (!shouldRefetch) {
        base.syncLogger.assessmentDetailFetch(assessmentId, online: false);
        if (base.serverReachabilityService.isServerReachable &&
            questions.isNotEmpty) {
          _backgroundFetchAssessmentDetail(base, assessmentId);
        }
        return Right(cached);
      }

      base.syncLogger.assessmentDetailFetch(assessmentId, online: true);
    } on CacheException {
      base.syncLogger.warn('Assessment detail not in cache for $assessmentId, fetching from server');
    }
    try {
      final fresh = await base.remoteDataSource.getAssessmentDetail(
          assessmentId: assessmentId);
      base.syncLogger.assessmentDetailResponse(assessmentId, fresh.questions.length);
      await base.localDataSource.cacheAssessmentDetail(
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

void _backgroundFetchAssessmentDetail(AssessmentRepositoryBase base, String assessmentId) {
  Future.microtask(() async {
    try {
      final fresh = await base.remoteDataSource.getAssessmentDetail(
          assessmentId: assessmentId);

      late Assessment cachedAssessment;
      late List<Question> cachedQuestions;
      try {
        final result =
            await base.localDataSource.getCachedAssessmentDetail(assessmentId);
        cachedAssessment = result.$1;
        cachedQuestions = result.$2;
      } on CacheException {
        await base.localDataSource.cacheAssessmentDetail(
            fresh.assessment, fresh.questions);
        base.dataEventBus.notifyAssessmentDetailChanged(assessmentId);
        return;
      }

      final changed = _assessmentDetailHasChanged(cachedAssessment, cachedQuestions,
          fresh.assessment, fresh.questions);
      base.syncLogger.assessmentDetailBackgroundFetch(assessmentId, changed: changed);

      if (changed) {
        await base.localDataSource.cacheAssessmentDetail(
            fresh.assessment, fresh.questions);
        base.dataEventBus.notifyAssessmentDetailChanged(assessmentId);
      }
    } catch (e) {
      base.syncLogger.warn('Background fetch failed for $assessmentId', e);
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
