import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

ResultFuture<List<TableOfSpecifications>> getTosList(
  TosLocalDataSource localDataSource,
  TosRemoteDataSource remoteDataSource, {
  required String classId,
}) async {
  try {
    try {
      final cached = await localDataSource.getTosByClass(classId);

      fireRemoteFetch(
        dedupKey: 'tos/tosList/$classId/bg',
        remote: () => remoteDataSource.getTosByClass(classId: classId),
        onSuccess: (fresh) async {
          try {
            final current = await localDataSource.getTosByClass(classId);
            if (current.length != fresh.length ||
                current.any((c) => !fresh.any((f) => f.id == c.id))) {
              await localDataSource.cacheTosList(fresh);
            }
          } on CacheException {
            await localDataSource.cacheTosList(fresh);
          }
        },
      );

      return Right(cached);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'tos/tosList/$classId',
        remote: () => remoteDataSource.getTosByClass(classId: classId),
      );
      await localDataSource.cacheTosList(fresh);
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
