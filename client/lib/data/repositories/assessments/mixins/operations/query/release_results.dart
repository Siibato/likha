import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';

ResultFuture<Assessment> releaseResults(
  AssessmentRepositoryBase base, {
  required String assessmentId,
}) async {
  try {
    if (!base.serverReachabilityService.isServerReachable) {
      await base.localDataSource.releaseResultsLocally(assessmentId: assessmentId);
      try {
        final (cached, _) =
            await base.localDataSource.getCachedAssessmentDetail(assessmentId);
        return Right(Assessment(
          id: cached.id,
          classId: cached.classId,
          title: cached.title,
          description: cached.description,
          timeLimitMinutes: cached.timeLimitMinutes,
          openAt: cached.openAt,
          closeAt: cached.closeAt,
          showResultsImmediately: cached.showResultsImmediately,
          resultsReleased: true,
          isPublished: cached.isPublished,
          orderIndex: cached.orderIndex,
          totalPoints: cached.totalPoints,
          questionCount: cached.questionCount,
          submissionCount: cached.submissionCount,
          createdAt: cached.createdAt,
          updatedAt: DateTime.now(),
        ));
      } catch (_) {
        return Right(Assessment(
          id: assessmentId,
          classId: '',
          title: '',
          description: null,
          timeLimitMinutes: 0,
          openAt: DateTime.now(),
          closeAt: DateTime.now(),
          showResultsImmediately: false,
          resultsReleased: true,
          isPublished: false,
          orderIndex: 0,
          totalPoints: 0,
          questionCount: 0,
          submissionCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }

    await base.localDataSource.releaseResultsLocally(assessmentId: assessmentId);

    final result =
        await base.remoteDataSource.releaseResults(assessmentId: assessmentId);
    await base.localDataSource.cacheAssessments([result]);
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
