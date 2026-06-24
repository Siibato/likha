import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import '_helpers.dart' as helpers;

ResultFuture<List<ClassEntity>> getAllClasses(
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource, {
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cachedClasses = await localDataSource.getCachedClasses();
      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'classes/allClasses/bg',
          remote: remoteDataSource.getAllClasses,
          onSuccess: (fresh) async {
            final current = await localDataSource.getCachedClasses();
            if (helpers.classesHaveChanged(current, fresh)) {
              await localDataSource.cacheClasses(fresh);
            }
          },
        );
      }
      return Right(cachedClasses);
    } on CacheException {
      final freshClasses = await remoteFetch(
        dedupKey: 'classes/allClasses',
        remote: remoteDataSource.getAllClasses,
      );
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
