import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultFuture<(Assessment, List<Question>)> getAssessmentDetail(
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String assessmentId,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedAssessmentDetail(assessmentId);
      final (assessment, questions) = cached;

      // Safety: if questions are empty, do a blocking fetch so the student
      // can actually take the assessment.
      if (questions.isEmpty) {
        final fresh = await remoteFetch(
          dedupKey: 'assessments/detail/$assessmentId',
          remote: () => remoteDataSource.getAssessmentDetail(assessmentId: assessmentId),
        );
        await localDataSource.cacheAssessmentDetail(fresh.assessment, fresh.questions);
        return Right((fresh.assessment, fresh.questions));
      }

      // Normal cache-first path: return immediately, refresh in background
      fireRemoteFetch(
        dedupKey: 'assessments/detail/$assessmentId/bg',
        remote: () => remoteDataSource.getAssessmentDetail(assessmentId: assessmentId),
        onSuccess: (fresh) async {
          try {
            final result = await localDataSource.getCachedAssessmentDetail(assessmentId);
            final cachedAssessment = result.$1;
            final cachedQuestions = result.$2;
            if (_assessmentDetailHasChanged(cachedAssessment, cachedQuestions, fresh.assessment, fresh.questions)) {
              await localDataSource.cacheAssessmentDetail(fresh.assessment, fresh.questions);
              dataEventBus.notifyAssessmentDetailChanged(assessmentId);
            }
          } on CacheException {
            await localDataSource.cacheAssessmentDetail(fresh.assessment, fresh.questions);
            dataEventBus.notifyAssessmentDetailChanged(assessmentId);
          }
        },
      );

      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'assessments/detail/$assessmentId',
        remote: () => remoteDataSource.getAssessmentDetail(assessmentId: assessmentId),
      );
      await localDataSource.cacheAssessmentDetail(fresh.assessment, fresh.questions);
      return Right((fresh.assessment, fresh.questions));
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
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
