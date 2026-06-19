import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';
import 'package:likha/domain/student_records/entities/attendance_record.dart';

ResultFuture<List<AttendanceRecord>> getAttendance(
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
      final cached = await localDataSource.getCachedAttendance(studentId, classId: classId, schoolYear: schoolYear);

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'studentRecords/attendance/$studentId/$schoolYear/bg',
          remote: () => remoteDataSource.getAttendance(classId: classId, studentId: studentId, schoolYear: schoolYear),
          onSuccess: (fresh) async {
            try {
              await localDataSource.cacheAttendance(fresh);
            } catch (_) {
              // Cache write failure is non-fatal for background refresh
            }
          },
        );
      }
      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'studentRecords/attendance/$studentId/$schoolYear',
        remote: () => remoteDataSource.getAttendance(classId: classId, studentId: studentId, schoolYear: schoolYear),
      );
      try {
        await localDataSource.cacheAttendance(fresh);
      } catch (_) {
        // Cache write failure is non-fatal; user still gets the data
      }
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
