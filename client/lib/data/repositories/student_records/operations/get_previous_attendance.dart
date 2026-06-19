import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';
import 'package:likha/domain/student_records/entities/previous_attendance.dart';

ResultFuture<List<PreviousAttendance>> getPreviousAttendance(
  StudentRecordsLocalDataSource localDataSource,
  StudentRecordsRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  required String studentId,
  String? schoolHistoryId,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedPreviousAttendance(studentId, schoolHistoryId: schoolHistoryId);
      if (cached.isEmpty) throw CacheException('No cached previous attendance');

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'studentRecords/prevAttendance/$studentId/${schoolHistoryId ?? 'all'}/bg',
          remote: () => remoteDataSource.getPreviousAttendance(classId: classId, studentId: studentId, schoolHistoryId: schoolHistoryId),
          onSuccess: (fresh) async {
            await localDataSource.cachePreviousAttendance(fresh);
          },
        );
      }
      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'studentRecords/prevAttendance/$studentId/${schoolHistoryId ?? 'all'}',
        remote: () => remoteDataSource.getPreviousAttendance(classId: classId, studentId: studentId, schoolHistoryId: schoolHistoryId),
      );
      await localDataSource.cachePreviousAttendance(fresh);
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
