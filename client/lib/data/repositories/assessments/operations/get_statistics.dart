import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
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
    // 1. Always compute locally from SQLite submissions/answers
    final local = await localDataSource.computeStatistics(assessmentId);
    if (local != null) {
      return Right(local);
    }

    final fresh = await remoteFetch(
      dedupKey: 'assessments/statistics/$assessmentId',
      remote: () => remoteDataSource.getStatistics(assessmentId: assessmentId),
    );
    return Right(fresh);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return const Left(CacheFailure('Statistics not available offline'));
  }
}
