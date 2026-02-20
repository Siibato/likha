import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';
import 'package:likha/data/datasources/local/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/check_username_result.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/services/storage_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;
  final StorageService _storageService;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivityService,
    this._storageService,
  );

  @override
  ResultFuture<CheckUsernameResult> checkUsername(
      {required String username}) async {
    try {
      final result =
          await _remoteDataSource.checkUsername(username: username);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> activateAccount({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final result = await _remoteDataSource.activateAccount(
        username: username,
        password: password,
        confirmPassword: confirmPassword,
      );
      return Right(result.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> login({
    required String username,
    required String password,
    String? deviceId,
  }) async {
    try {
      final result = await _remoteDataSource.login(
        username: username,
        password: password,
        deviceId: deviceId,
      );
      return Right(result.user);
    } on ActivationRequiredException catch (e) {
      return Left(ActivationRequiredFailure(
        e.message,
        username: e.username,
        fullName: e.fullName,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> refreshToken() async {
    try {
      final token = await _storageService.getRefreshToken();
      if (token == null) {
        return const Left(UnauthorizedFailure('No refresh token found'));
      }

      final result = await _remoteDataSource.refreshToken(token);
      return Right(result.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> getCurrentUser() async {
    // Online-first routing with fallback to offline cache
    if (_connectivityService.isOnline) {
      try {
        final user = await _remoteDataSource.getCurrentUser();
        // Fire-and-forget cache update
        unawaited(_localDataSource.cacheCurrentUser(user));
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (_) {
        // Flaky connection - fall through to cache
      } on UnauthorizedException catch (e) {
        return Left(UnauthorizedFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }

    // Offline or network failure - use cached data
    try {
      final cachedUser = await _localDataSource.getCachedCurrentUser();
      return Right(cachedUser);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid logout() async {
    try {
      final token = await _storageService.getRefreshToken();
      if (token != null) {
        await _remoteDataSource.logout(token);
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() {
    return _storageService.isAuthenticated();
  }

  // ===== Admin methods =====

  @override
  ResultFuture<User> createAccount({
    required String username,
    required String fullName,
    required String role,
  }) async {
    try {
      final result = await _remoteDataSource.createAccount(
        username: username,
        fullName: fullName,
        role: role,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<User>> getAllAccounts() async {
    // Online-first routing with fallback to offline cache for admin reads
    if (_connectivityService.isOnline) {
      try {
        final result = await _remoteDataSource.getAllAccounts();
        // Fire-and-forget cache update
        unawaited(_localDataSource.cacheAccounts(result));
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (_) {
        // Flaky connection - fall through to cache
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }

    // Offline or network failure - use cached data
    try {
      final cachedAccounts = await _localDataSource.getCachedAccounts();
      return Right(cachedAccounts);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> resetAccount({required String userId}) async {
    try {
      final result = await _remoteDataSource.resetAccount(userId: userId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> lockAccount(
      {required String userId, required bool locked}) async {
    try {
      final result =
          await _remoteDataSource.lockAccount(userId: userId, locked: locked);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<ActivityLog>> getActivityLogs(
      {required String userId}) async {
    try {
      final result =
          await _remoteDataSource.getActivityLogs(userId: userId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> updateAccount({
    required String userId,
    String? username,
    String? fullName,
  }) async {
    try {
      final result = await _remoteDataSource.updateAccount(
        userId: userId,
        username: username,
        fullName: fullName,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
