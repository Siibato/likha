import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';

ResultFuture<SubmissionAnswer> gradeEssayAnswer(
  AssessmentRepositoryBase base, {
  required String answerId,
  required double points,
}) async {
  try {
    // Always write locally first (optimistic)
    await base.localDataSource.gradeEssay(
      answerId: answerId,
      points: points,
    );

    if (base.serverReachabilityService.isServerReachable) {
      try {
        final result = await base.remoteDataSource.gradeEssayAnswer(
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
