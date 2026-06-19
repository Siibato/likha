import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';
import 'package:likha/domain/student_records/entities/core_values_record.dart';

ResultFuture<List<CoreValuesRecord>> getCoreValues(
  StudentRecordsLocalDataSource localDataSource,
  StudentRecordsRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  required String studentId,
  String? schoolYear,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedCoreValues(studentId, classId: classId, schoolYear: schoolYear);
      if (cached.isEmpty) throw CacheException('No cached core values');

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'studentRecords/coreValues/$studentId/$schoolYear/bg',
          remote: () => remoteDataSource.getCoreValues(classId: classId, studentId: studentId, schoolYear: schoolYear),
          onSuccess: (fresh) async {
            await localDataSource.cacheCoreValues(fresh);
            dataEventBus.notifyCoreValuesChanged(studentId);
          },
        );
      }
      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'studentRecords/coreValues/$studentId/$schoolYear',
        remote: () => remoteDataSource.getCoreValues(classId: classId, studentId: studentId, schoolYear: schoolYear),
      );
      await localDataSource.cacheCoreValues(fresh);
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
