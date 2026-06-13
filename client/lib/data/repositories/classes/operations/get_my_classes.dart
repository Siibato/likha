import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/services/storage_service.dart';
import '_helpers.dart' as helpers;

ResultFuture<List<ClassEntity>> getMyClasses(
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus,
  StorageService storageService, {
  bool skipBackgroundRefresh = false,
}) async {
  try {
    final currentUserId = await helpers.getCurrentUserId(storageService);
    if (currentUserId == null) return const Right([]);

    try {
      // Works for both students (enrolled via class_participants) and
      // teachers (also present in class_participants with role='teacher')
      final cachedClasses = await localDataSource.getCachedClassesForUser(currentUserId);
      // Cache hit: return immediately, fire background refresh
      if (!skipBackgroundRefresh) {
        helpers.backgroundFetchMyClasses(remoteDataSource, localDataSource, dataEventBus, storageService);
      }
      return Right(cachedClasses);
    } on CacheException {
      // Cache miss: blocking remote fetch (avoids empty-state flash)
      final freshClasses = await remoteDataSource.getMyClasses();
      await localDataSource.cacheClasses(freshClasses);
      await helpers.cacheStudentParticipations(localDataSource, freshClasses, currentUserId);
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
