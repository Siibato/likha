import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import '_helpers.dart' as helpers;

ResultFuture<List<ClassEntity>> getAllClasses(
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cachedClasses = await localDataSource.getCachedClasses();
      // Cache hit: return immediately, fire background refresh
      if (!skipBackgroundRefresh) {
        helpers.backgroundFetchAllClasses(remoteDataSource, localDataSource, dataEventBus);
      }
      return Right(cachedClasses);
    } on CacheException {
      // Cache miss: blocking remote fetch (avoids empty-state flash)
      final freshClasses = await remoteDataSource.getAllClasses();
      await localDataSource.cacheClasses(freshClasses);
      return Right(freshClasses);
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
