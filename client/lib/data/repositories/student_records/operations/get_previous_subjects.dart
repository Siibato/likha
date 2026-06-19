import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';
import 'package:likha/domain/student_records/entities/previous_subject.dart';

ResultFuture<List<PreviousSubject>> getPreviousSubjects(
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
      final cached = await localDataSource.getCachedPreviousSubjects(studentId, schoolHistoryId: schoolHistoryId);
      if (cached.isEmpty) throw CacheException('No cached previous subjects');

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'studentRecords/prevSubjects/$studentId/${schoolHistoryId ?? 'all'}/bg',
          remote: () => remoteDataSource.getPreviousSubjects(classId: classId, studentId: studentId, schoolHistoryId: schoolHistoryId),
          onSuccess: (fresh) async {
            await localDataSource.cachePreviousSubjects(fresh);
            if (schoolHistoryId != null) {
              dataEventBus.notifyPreviousSubjectsChanged(schoolHistoryId);
            }
          },
        );
      }
      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'studentRecords/prevSubjects/$studentId/${schoolHistoryId ?? 'all'}',
        remote: () => remoteDataSource.getPreviousSubjects(classId: classId, studentId: studentId, schoolHistoryId: schoolHistoryId),
      );
      await localDataSource.cachePreviousSubjects(fresh);
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
