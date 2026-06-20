import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';

ResultFuture<List<SchoolHistory>> getSchoolHistory(
  StudentRecordsLocalDataSource localDataSource,
  StudentRecordsRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  required String studentId,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedSchoolHistory(studentId);
      if (cached.isEmpty) throw CacheException('No cached school history');

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'studentRecords/schoolHistory/$studentId/bg',
          remote: () => remoteDataSource.getSchoolHistory(classId: classId, studentId: studentId),
          onSuccess: (fresh) async {
            await localDataSource.cacheSchoolHistory(fresh);
          },
        );
      }
      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'studentRecords/schoolHistory/$studentId',
        remote: () => remoteDataSource.getSchoolHistory(classId: classId, studentId: studentId),
      );
      await localDataSource.cacheSchoolHistory(fresh);
      return Right(fresh);
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
