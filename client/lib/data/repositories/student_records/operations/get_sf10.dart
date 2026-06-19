import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';
import 'package:likha/data/models/student_records/sf10_response_model.dart';
import 'package:likha/domain/student_records/entities/sf10_response.dart';

ResultFuture<Sf10Response> getSf10(
  GradingLocalDataSource localDataSource,
  StudentRecordsRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  required String studentId,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedSf10(classId, studentId);
      if (cached.isEmpty) throw CacheException('No cached SF10');

      final cachedModel = Sf10ResponseModel.fromJson(cached);

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'studentRecords/sf10/$classId/$studentId/bg',
          remote: () => remoteDataSource.getSf10(classId: classId, studentId: studentId),
          onSuccess: (fresh) async {
            await localDataSource.cacheSf10(classId, studentId, fresh.toJson());
            dataEventBus.notifySf10Changed(classId);
          },
        );
      }
      return Right(cachedModel);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'studentRecords/sf10/$classId/$studentId',
        remote: () => remoteDataSource.getSf10(classId: classId, studentId: studentId),
      );
      await localDataSource.cacheSf10(classId, studentId, fresh.toJson());
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
