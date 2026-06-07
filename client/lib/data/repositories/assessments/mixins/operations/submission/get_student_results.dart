import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';

ResultFuture<StudentResult> getStudentResults(
  AssessmentRepositoryBase base, {
  required String submissionId,
}) async {
  try {
    final cached =
        await base.localDataSource.getCachedStudentResults(submissionId);
    if (cached != null) return Right(cached);

    try {
      final result = await base.remoteDataSource.getStudentResults(
          submissionId: submissionId);
      await base.localDataSource.cacheStudentResults(result);
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  } catch (e) {
    return const Left(CacheFailure('Student results not available offline'));
  }
}
