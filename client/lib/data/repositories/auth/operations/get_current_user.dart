import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/services/storage_service.dart';

ResultFuture<User> getCurrentUser(
  ServerReachabilityService serverReachabilityService,
  AuthRemoteDataSource remoteDataSource,
  AuthLocalDataSource localDataSource,
  StorageService storageService,
) async {
  if (serverReachabilityService.isServerReachable) {
    try {
      final user = await remoteDataSource.getCurrentUser();
      unawaited(localDataSource.cacheCurrentUser(user));
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (_) {
      // Flaky connection — fall through to cache
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  try {
    final storedUserId = await storageService.getUserId();
    if (storedUserId == null) {
      return const Left(UnauthorizedFailure('Not authenticated'));
    }

    final cachedUser = await localDataSource.getCachedCurrentUser(storedUserId);

    return Right(cachedUser);
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
