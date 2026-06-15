import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';

ResultFuture<Map<String, dynamic>> getMyGradeDetail(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  required int gradingPeriodNumber,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedMyGradeDetail(
        classId,
        gradingPeriodNumber,
      );

      // Treat empty map as cache miss
      if (cached.isEmpty) {
        throw CacheException('No cached my grade detail found');
      }

      fireRemoteFetch(
        dedupKey: 'grading/myGradeDetail/$classId/$gradingPeriodNumber/bg',
        remote: () => remoteDataSource.getMyGradeDetail(
          classId: classId,
          gradingPeriodNumber: gradingPeriodNumber,
        ),
        onSuccess: (fresh) async {
          try {
            final current = await localDataSource.getCachedMyGradeDetail(
              classId,
              gradingPeriodNumber,
            );
            if (_myGradeDetailHasChanged(current, fresh)) {
              await localDataSource.cacheMyGradeDetail(
                classId,
                gradingPeriodNumber,
                fresh,
              );
              dataEventBus.notifyMyGradeDetailChanged(classId);
            }
          } catch (_) {
            await localDataSource.cacheMyGradeDetail(
              classId,
              gradingPeriodNumber,
              fresh,
            );
            dataEventBus.notifyMyGradeDetailChanged(classId);
          }
        },
      );

      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'grading/myGradeDetail/$classId/$gradingPeriodNumber',
        remote: () => remoteDataSource.getMyGradeDetail(
          classId: classId,
          gradingPeriodNumber: gradingPeriodNumber,
        ),
      );
      await localDataSource.cacheMyGradeDetail(
        classId,
        gradingPeriodNumber,
        fresh,
      );
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

bool _myGradeDetailHasChanged(
  Map<String, dynamic> current,
  Map<String, dynamic> fresh,
) {
  return current.length != fresh.length ||
      current.keys.any((k) => current[k].toString() != fresh[k].toString());
}
