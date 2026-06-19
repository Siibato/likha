import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';

ResultFuture<LearnerDetails?> getLearnerDetails(
  StudentRecordsLocalDataSource localDataSource,
  StudentRecordsRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  required String studentId,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedLearnerDetails(studentId);
      if (cached == null) throw CacheException('No cached learner details');

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'studentRecords/learnerDetails/$studentId/bg',
          remote: () => remoteDataSource.getLearnerDetails(classId: classId, studentId: studentId),
          onSuccess: (fresh) async {
            await localDataSource.cacheLearnerDetails(fresh);
            dataEventBus.notifyLearnerDetailsChanged(studentId);
          },
        );
      }
      return Right(cached);
    } on CacheException {
      try {
        final fresh = await remoteFetch(
          dedupKey: 'studentRecords/learnerDetails/$studentId',
          remote: () => remoteDataSource.getLearnerDetails(classId: classId, studentId: studentId),
        );
        await localDataSource.cacheLearnerDetails(fresh);
        return Right(fresh);
      } on ServerException catch (e) {
        if (e.statusCode == 404) return const Right(null);
        rethrow;
      }
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
