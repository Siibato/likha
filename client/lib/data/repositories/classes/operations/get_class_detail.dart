import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import '_helpers.dart' as helpers;

ResultFuture<ClassDetail> getClassDetail(
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cached = await localDataSource.getCachedClassDetail(classId);

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'classes/detail/$classId/bg',
          remote: () => remoteDataSource.getClassDetail(classId: classId),
          onSuccess: (fresh) async {
            final current = await localDataSource.getCachedClassDetail(classId);
            if (helpers.classDetailHasChanged(current, fresh)) {
              await localDataSource.cacheClassDetail(fresh);
              dataEventBus.notifyClassDetailChanged(classId);
            }
          },
        );
      }

      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'classes/detail/$classId',
        remote: () => remoteDataSource.getClassDetail(classId: classId),
      );
      await localDataSource.cacheClassDetail(fresh);
      return Right(fresh);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
