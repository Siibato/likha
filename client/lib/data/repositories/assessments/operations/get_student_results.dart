import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultFuture<StudentResult> getStudentResults(
  AssessmentLocalDataSource localDataSource,
  AssessmentRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String submissionId,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedStudentResults(submissionId);
      if (cached != null) {
        fireRemoteFetch(
          dedupKey: 'assessments/studentResults/$submissionId/bg',
          remote: () => remoteDataSource.getStudentResults(submissionId: submissionId),
          onSuccess: (fresh) async {
            final current = await localDataSource.getCachedStudentResults(submissionId);
            if (current == null || current != fresh) {
              await localDataSource.cacheStudentResults(fresh);
              dataEventBus.notifyStudentResultsChanged(submissionId);
            }
          },
        );
        return Right(cached);
      }

      final fresh = await remoteFetch(
        dedupKey: 'assessments/studentResults/$submissionId',
        remote: () => remoteDataSource.getStudentResults(submissionId: submissionId),
      );
      await localDataSource.cacheStudentResults(fresh);
      return Right(fresh);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'assessments/studentResults/$submissionId',
        remote: () => remoteDataSource.getStudentResults(submissionId: submissionId),
      );
      await localDataSource.cacheStudentResults(fresh);
      return Right(fresh);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return const Left(CacheFailure('Student results not available offline'));
  }
}
