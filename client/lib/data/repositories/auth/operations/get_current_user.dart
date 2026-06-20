import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/services/storage_service.dart';

ResultFuture<User> getCurrentUser(
  AuthRemoteDataSource remoteDataSource,
  AuthLocalDataSource localDataSource,
  StorageService storageService,
  DataEventBus dataEventBus, {
  bool skipBackgroundRefresh = false,
}) async {
  try {
    final storedUserId = await storageService.getUserId();
    if (storedUserId == null) {
      return const Left(UnauthorizedFailure('Not authenticated'));
    }

    try {
      final cachedUser = await localDataSource.getCachedCurrentUser(storedUserId);

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'auth/currentUser/$storedUserId/bg',
          remote: remoteDataSource.getCurrentUser,
          onSuccess: (fresh) async {
            final current = await localDataSource.getCachedCurrentUser(storedUserId);
            if (current != fresh) {
              await localDataSource.cacheCurrentUser(fresh);
              dataEventBus.notifyCurrentUserChanged();
            }
          },
        );
      }

      return Right(cachedUser);
    } on CacheException {
      final fresh = await remoteFetch(
        dedupKey: 'auth/currentUser/$storedUserId',
        remote: remoteDataSource.getCurrentUser,
      );
      await localDataSource.cacheCurrentUser(fresh);
      return Right(fresh);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on UnauthorizedException catch (e) {
    return Left(UnauthorizedFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
