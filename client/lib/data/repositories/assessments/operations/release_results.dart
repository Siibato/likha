import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultFuture<Assessment> releaseResults(
  ServerReachabilityService serverReachabilityService,
AssessmentLocalDataSource localDataSource,
AssessmentRemoteDataSource remoteDataSource, {
  required String assessmentId,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      await localDataSource.releaseResults(assessmentId: assessmentId);
      try {
        final (cached, _) =
            await localDataSource.getCachedAssessmentDetail(assessmentId);
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

    await localDataSource.releaseResults(assessmentId: assessmentId);

    final result =
        await remoteDataSource.releaseResults(assessmentId: assessmentId);
    await localDataSource.cacheAssessments([result]);
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
