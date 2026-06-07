import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';

ResultFuture<SubmissionAnswer> overrideAnswer(
  AssessmentRepositoryBase base, {
  required String answerId,
  required bool isCorrect,
  double? points,
}) async {
  try {
    if (!base.serverReachabilityService.isServerReachable) {
      await base.localDataSource.overrideAnswerLocally(
        answerId: answerId,
        isCorrect: isCorrect,
        points: points,
      );
      return Right(SubmissionAnswer(
        id: answerId,
        questionId: '',
        questionText: '',
        questionType: '',
        points: 0,
        isOverrideCorrect: isCorrect,
        pointsAwarded: points ?? (isCorrect ? 0 : 0),
      ));
    }

    final result = await base.remoteDataSource.overrideAnswer(
        answerId: answerId, isCorrect: isCorrect, points: points);
    return Right(result);
  } on NetworkException catch (_) {
    await base.localDataSource.overrideAnswerLocally(
      answerId: answerId,
      isCorrect: isCorrect,
      points: points,
    );
    return Right(SubmissionAnswer(
      id: answerId,
      questionId: '',
      questionText: '',
      questionType: '',
      points: 0,
      isOverrideCorrect: isCorrect,
      pointsAwarded: points ?? (isCorrect ? 0 : 0),
    ));
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
