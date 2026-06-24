import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';

ResultFuture<List<ActivityLog>> getActivityLogs(
  AuthLocalDataSource localDataSource,
  AuthRemoteDataSource remoteDataSource, {
  required String userId,
}) async {
  try {
    try {
      final cachedLogs = await localDataSource.getCachedActivityLogs(userId);
      fireRemoteFetch(
        dedupKey: 'auth/activityLogs/$userId/bg',
        remote: () => remoteDataSource.getActivityLogs(userId: userId),
        onSuccess: (fresh) async {
          final current = await localDataSource.getCachedActivityLogs(userId);
          if (current.length != fresh.length ||
              current.any((c) => !fresh.any((f) => f.id == c.id))) {
            await localDataSource.cacheActivityLogs(fresh, userId);
          }
        },
      );
      return Right(cachedLogs);
    } on CacheException {
      final freshLogs = await remoteFetch(
        dedupKey: 'auth/activityLogs/$userId',
        remote: () => remoteDataSource.getActivityLogs(userId: userId),
      );
      await localDataSource.cacheActivityLogs(freshLogs, userId);
      return Right(freshLogs);
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
