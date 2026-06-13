import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultFuture<SubmissionAnswer> gradeEssayAnswer(
  ServerReachabilityService serverReachabilityService,
AssessmentLocalDataSource localDataSource,
AssessmentRemoteDataSource remoteDataSource, {
  required String answerId,
  required double points,
}) async {
  try {
    // Always write locally first (optimistic)
    await localDataSource.gradeEssay(
      answerId: answerId,
      points: points,
    );

    if (serverReachabilityService.isServerReachable) {
      try {
        final result = await remoteDataSource.gradeEssayAnswer(
          answerId: answerId,
          points: points,
        );
        return Right(result);
      } on NetworkException catch (_) {
        // Swallow – change is already persisted locally and sync-queued
      }
    }

    return Right(SubmissionAnswer(
      id: answerId,
      questionId: '',
      questionText: '',
      questionType: '',
      points: 0,
      pointsAwarded: points,
      isPendingEssayGrade: false,
    ));
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
