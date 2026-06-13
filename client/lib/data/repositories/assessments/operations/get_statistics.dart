import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultFuture<AssessmentStatistics> getStatistics(
  AssessmentLocalDataSource localDataSource,
AssessmentRemoteDataSource remoteDataSource, {
  required String assessmentId,
}) async {
  try {
    final cached =
        await localDataSource.getCachedStatistics(assessmentId);
    if (cached != null) return Right(cached);

    try {
      final result =
          await remoteDataSource.getStatistics(assessmentId: assessmentId);
      await localDataSource.cacheStatistics(result);
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  } catch (e) {
    return const Left(CacheFailure('Statistics not available offline'));
  }
}
