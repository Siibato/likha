import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/datasources/local/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/check_username_result.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final ServerReachabilityService _serverReachabilityService;
  final StorageService _storageService;
  final SyncQueue _syncQueue;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._serverReachabilityService,
    this._storageService,
    this._syncQueue,
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
    if (_serverReachabilityService.isServerReachable) {
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
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation locally
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.adminUser,
          operation: SyncOperation.create,
          payload: {
            'username': username,
            'full_name': fullName,
            'role': role,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        // Return optimistic user for UI
        final optimisticUser = User(
          id: '',
          username: username,
          fullName: fullName,
          role: role,
          accountStatus: 'pending_activation',
          isActive: false,
          activatedAt: null,
          createdAt: DateTime.now(),
        );

        return Right(optimisticUser);
      }

      // Online: send to server
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
    try {
      // Step 1: Return cached data immediately (cache-first pattern)
      try {
        var cachedAccounts = await _localDataSource.getCachedAccounts();

        // Step 2: Get pending account creations from sync queue
        final pendingEntries = await _syncQueue.getAllRetriable();
        final pendingAccounts = <UserModel>[];

        for (final entry in pendingEntries) {
          if (entry.entityType == SyncEntityType.adminUser &&
              entry.operation == SyncOperation.create) {
            final payload = entry.payload;
            pendingAccounts.add(
              UserModel(
                id: '',
                username: payload['username'] as String? ?? '',
                fullName: payload['full_name'] as String? ?? '',
                role: payload['role'] as String? ?? '',
                accountStatus: 'pending_activation',
                isActive: false,
                activatedAt: null,
                createdAt: DateTime.now(),
              ),
            );
          }
        }

        // Step 3: Merge cached and pending accounts
        cachedAccounts = [...cachedAccounts, ...pendingAccounts];

        // Step 4: Sync in background (don't await)
        _syncAccountsInBackground();

        return Right(cachedAccounts);
      } on CacheException {
        // Cache empty, try to fetch from server
        if (!_serverReachabilityService.isServerReachable) {
          return Left(NetworkFailure('No internet connection and no cached data'));
        }

        final freshAccounts = await _remoteDataSource.getAllAccounts();
        await _localDataSource.cacheAccounts(freshAccounts);
        return Right(freshAccounts);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Sync accounts in background
  Future<void> _syncAccountsInBackground() async {
    if (!_serverReachabilityService.isServerReachable) return;

    try {
      final remoteAccounts = await _remoteDataSource.getAllAccounts();
      await _localDataSource.cacheAccounts(remoteAccounts);
    } catch (e) {
      // Best-effort: if sync fails, continue with cached data
    }
  }

  @override
  ResultFuture<User> resetAccount({required String userId}) async {
    try {
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.adminUser,
          operation: SyncOperation.update,
          payload: {
            'id': userId,
            'action': 'reset',
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        // Return optimistic response with reset state
        return Right(User(
          id: userId,
          username: '',
          fullName: '',
          role: '',
          accountStatus: 'pending_activation',
          isActive: false,
          activatedAt: null,
          createdAt: DateTime.now(),
        ));
      }

      // Online: send to server
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
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.adminUser,
          operation: SyncOperation.update,
          payload: {
            'id': userId,
            'action': 'lock',
            'locked': locked,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        // Return optimistic response with lock state
        return Right(User(
          id: userId,
          username: '',
          fullName: '',
          role: '',
          accountStatus: locked ? 'locked' : 'active',
          isActive: !locked,
          activatedAt: null,
          createdAt: DateTime.now(),
        ));
      }

      // Online: send to server
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
      // Step 1: Return cached data immediately (cache-first pattern)
      try {
        final cachedLogs = await _localDataSource.getCachedActivityLogs(userId);

        // Step 2: Sync in background (don't await)
        _syncActivityLogsInBackground(userId);

        return Right(cachedLogs);
      } on CacheException {
        // Cache empty, try to fetch from server
        if (!_serverReachabilityService.isServerReachable) {
          return Left(NetworkFailure('No internet connection and no cached data'));
        }

        final freshLogs = await _remoteDataSource.getActivityLogs(userId: userId);
        await _localDataSource.cacheActivityLogs(freshLogs as List<ActivityLogModel>, userId);
        return Right(freshLogs);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Sync activity logs in background
  Future<void> _syncActivityLogsInBackground(String userId) async {
    if (!_serverReachabilityService.isServerReachable) return;

    try {
      final remoteActivityLogs = await _remoteDataSource.getActivityLogs(userId: userId);
      await _localDataSource.cacheActivityLogs(remoteActivityLogs as List<ActivityLogModel>, userId);
    } catch (e) {
      // Best-effort: if sync fails, continue with cached data
    }
  }

  @override
  ResultFuture<User> updateAccount({
    required String userId,
    String? username,
    String? fullName,
  }) async {
    try {
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.adminUser,
          operation: SyncOperation.update,
          payload: {
            'id': userId,
            'action': 'update',
            if (username != null) 'username': username,
            if (fullName != null) 'full_name': fullName,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        // Return optimistic user with updated fields
        return Right(User(
          id: userId,
          username: username ?? '',
          fullName: fullName ?? '',
          role: '',
          accountStatus: 'active',
          isActive: true,
          activatedAt: null,
          createdAt: DateTime.now(),
        ));
      }

      // Online: send to server
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
