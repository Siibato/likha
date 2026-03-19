import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/repositories/auth/auth_repository_base.dart';
import 'package:likha/domain/auth/entities/check_username_result.dart';
import 'package:likha/domain/auth/entities/user.dart';

mixin AuthLoginMixin on AuthRepositoryBase {
  @override
  ResultFuture<CheckUsernameResult> checkUsername({
    required String username,
  }) async {
    try {
      final result = await remoteDataSource.checkUsername(username: username);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
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
      final result = await remoteDataSource.activateAccount(
        username: username,
        password: password,
        confirmPassword: confirmPassword,
      );
      return Right(result.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
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
      final result = await remoteDataSource.login(
        username: username,
        password: password,
        deviceId: deviceId,
      );

      // Detect user change and clear cache if a different user is logging in
      final previousUserId = await storageService.getUserId();
      if (previousUserId != null && previousUserId != result.user.id) {
        await clearAllUserData();
      }

      unawaited(localDataSource.cacheCurrentUser(result.user));
      unawaited(storageService.saveUserRole(result.user.role));

      return Right(result.user);
    } on TooManyRequestsException catch (e) {
      return Left(TooManyRequestsFailure(e.message, remainingSeconds: e.remainingSeconds));
    } on InvalidCredentialsException catch (e) {
      return Left(InvalidCredentialsFailure(e.message, attemptsRemaining: e.attemptsRemaining));
    } on ActivationRequiredException catch (e) {
      return Left(ActivationRequiredFailure(
        e.message,
        username: e.username,
        fullName: e.fullName,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
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
      final token = await storageService.getRefreshToken();
      if (token == null) {
        return const Left(UnauthorizedFailure('No refresh token found'));
      }

      final result = await remoteDataSource.refreshToken(token);
      return Right(result.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
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

  @override
  ResultVoid logout() async {
    try {
      final token = await storageService.getRefreshToken();
      if (token != null) {
        await remoteDataSource.logout(token);
      }
      unawaited(clearAllUserData());
      return const Right(null);
    } on ServerException catch (e) {
      unawaited(clearAllUserData());
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      unawaited(clearAllUserData());
      return Left(NetworkFailure(e.message));
    } catch (e) {
      unawaited(clearAllUserData());
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() {
    return storageService.isAuthenticated();
  }
}