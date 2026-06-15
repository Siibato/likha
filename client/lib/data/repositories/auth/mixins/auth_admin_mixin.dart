import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/repositories/auth/auth_repository_base.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:uuid/uuid.dart';

mixin AuthAdminMixin on AuthRepositoryBase {
  @override
  ResultFuture<User> createAccount({
    required String username,
    required String fullName,
    required String role,
  }) async {
    RepoLogger.instance.log('createAccount START: username=$username, fullName=$fullName, role=$role');
    try {
      final isServerReachable = serverReachabilityService.isServerReachable;
      RepoLogger.instance.log('Server reachable: $isServerReachable');
      
      if (!isServerReachable) {
        RepoLogger.instance.log('Entering offline flow for account creation');
        RepoLogger.instance.log('Building pending accounts to check for duplicates');
        final pendingAccounts = await _buildPendingAccounts();
        RepoLogger.instance.log('Pending accounts count: ${pendingAccounts.length}');
        if (pendingAccounts.any((a) => a.username.toLowerCase() == username.toLowerCase())) {
          RepoLogger.instance.warn('Username $username already in pending accounts');
          return Left(ServerFailure('Account "$username" already exists.'));
        }

        try {
          RepoLogger.instance.log('Checking cached accounts for duplicate username');
          final cachedAccounts = await localDataSource.getCachedAccounts();
          RepoLogger.instance.log('Cached accounts count: ${cachedAccounts.length}');
          if (cachedAccounts.any((a) => a.username.toLowerCase() == username.toLowerCase())) {
            RepoLogger.instance.warn('Username $username already exists in cache');
            return Left(ServerFailure('Account "$username" already exists.'));
          }
        } on CacheException catch (e) {
          RepoLogger.instance.warn('CacheException while checking cached accounts', e);
        }

        // Generate a UUID for the offline-created user (permanent ID shared with server)
        final localId = const Uuid().v4();
        RepoLogger.instance.log('Generated local ID: $localId');

        RepoLogger.instance.log('Enqueuing sync queue entry for offline account creation');
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.adminUser,
          operation: SyncOperation.create,
          payload: {
            'id': localId,
            'username': username,
            'full_name': fullName,
            'role': role,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
        RepoLogger.instance.log('Sync queue entry enqueued successfully');

        RepoLogger.instance.log('Creating optimistic user model');
        final optimisticUser = UserModel(
          id: localId,
          username: username,
          fullName: fullName,
          role: role,
          accountStatus: 'pending_activation',
          isActive: false,
          activatedAt: null,
          createdAt: DateTime.now(),
        );
        RepoLogger.instance.log('Optimistic user created: id=${optimisticUser.id}, username=${optimisticUser.username}');

        try {
          RepoLogger.instance.log('Caching created account locally');
          await localDataSource.cacheCreatedAccount(optimisticUser);
          RepoLogger.instance.log('Account cached successfully');
        } catch (e) {
          RepoLogger.instance.warn('Cache failure while caching created account (non-critical)', e);
          // Cache failure is not critical
        }

        RepoLogger.instance.log('createAccount SUCCESS (offline): returning optimistic user');
        return Right(optimisticUser);
      }

      RepoLogger.instance.log('Entering online flow for account creation');
      final result = await remoteDataSource.createAccount(
        username: username,
        fullName: fullName,
        role: role,
      );
      RepoLogger.instance.log('createAccount SUCCESS (online): account created on server');
      return Right(result);
    } on ServerException catch (e) {
      RepoLogger.instance.error('ServerException in createAccount', e);
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      RepoLogger.instance.error('NetworkException in createAccount', e);
      return Left(NetworkFailure(e.message));
    } catch (e) {
      RepoLogger.instance.error('Unexpected exception in createAccount', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<User>> getAllAccounts() async {
    RepoLogger.instance.log('getAllAccounts START');
    try {
      var cachedAccounts = <UserModel>[];
      bool hasCachedData = false;

      try {
        cachedAccounts = await localDataSource.getCachedAccounts();
        hasCachedData = true;
        RepoLogger.instance.log('getAllAccounts: Found ${cachedAccounts.length} cached accounts');
      } on CacheException {
        hasCachedData = false;
        RepoLogger.instance.log('getAllAccounts: No cached data available');
      }

      RepoLogger.instance.log('getAllAccounts: serverReachable=${serverReachabilityService.isServerReachable}');
      if (serverReachabilityService.isServerReachable) {
        RepoLogger.instance.log('getAllAccounts: Attempting server fetch');
        try {
          final freshAccounts = await remoteDataSource.getAllAccounts();
          RepoLogger.instance.log('getAllAccounts: Server fetch returned ${freshAccounts.length} accounts');
          await localDataSource.cacheAccounts(freshAccounts);
          RepoLogger.instance.log('getAllAccounts: Cached ${freshAccounts.length} accounts locally');

          final pendingAccounts = await _buildPendingAccounts();
          RepoLogger.instance.log('getAllAccounts: Found ${pendingAccounts.length} pending accounts');
          // Final dedup: remove pending accounts that already exist in server accounts
          final serverUsernames = freshAccounts.map((a) => a.username).toSet();
          final deduped = pendingAccounts
              .where((p) => !serverUsernames.contains(p.username))
              .toList();
          final result = [...freshAccounts, ...deduped];
          RepoLogger.instance.log('getAllAccounts: Returning ${result.length} total accounts (server + pending)');
          return Right(result);
        } catch (e) {
          RepoLogger.instance.error('getAllAccounts: Server fetch failed - $e');
          if (!hasCachedData) {
            if (e is ServerException) return Left(ServerFailure(e.message));
            if (e is NetworkException) return Left(NetworkFailure(e.message));
            return Left(ServerFailure(e.toString()));
          }
          // Has cache — fall through
          RepoLogger.instance.log('getAllAccounts: Falling back to cache');
        }
      } else {
        RepoLogger.instance.log('getAllAccounts: Server not reachable, skipping server fetch');
      }

      final pendingAccounts = await _buildPendingAccounts();

      if (hasCachedData) {
        // Final dedup: remove pending accounts that already exist in cached accounts
        final cachedUsernames = cachedAccounts.map((a) => a.username).toSet();
        final deduped = pendingAccounts
            .where((p) => !cachedUsernames.contains(p.username))
            .toList();
        final result = [...cachedAccounts, ...deduped];
        RepoLogger.instance.log('getAllAccounts: Returning ${result.length} accounts from cache + pending');
        return Right(result);
      }

      if (pendingAccounts.isNotEmpty) {
        RepoLogger.instance.log('getAllAccounts: Returning ${pendingAccounts.length} pending accounts only');
        return Right(pendingAccounts);
      }

      RepoLogger.instance.log('getAllAccounts: No data available - returning error');
      return const Left(NetworkFailure('No internet connection and no cached data'));
    } on ServerException catch (e) {
      RepoLogger.instance.error('getAllAccounts: ServerException - ${e.message}');
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      RepoLogger.instance.error('getAllAccounts: NetworkException - ${e.message}');
      return Left(NetworkFailure(e.message));
    } catch (e) {
      RepoLogger.instance.error('getAllAccounts: Unexpected error - $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> resetAccount({required String userId}) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.adminUser,
          operation: SyncOperation.update,
          payload: {'id': userId, 'action': 'reset'},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        // Read existing user to preserve all fields
        UserModel? existingUser;
        try {
          existingUser = await localDataSource.getCachedUser(userId);
        } on CacheException {
          // User not in cache — fall back to minimal optimistic
        }

        final optimisticUser = existingUser != null
            ? UserModel(
                id: existingUser.id,
                username: existingUser.username,
                fullName: existingUser.fullName,
                role: existingUser.role,
                accountStatus: 'pending_activation',
                isActive: false,
                activatedAt: null,
                createdAt: existingUser.createdAt,
              )
            : UserModel(
                id: userId,
                username: '',
                fullName: '(Unknown)',
                role: '',
                accountStatus: 'pending_activation',
                isActive: false,
                activatedAt: null,
                createdAt: DateTime.now(),
              );

        try {
          await localDataSource.cacheAccounts([optimisticUser]);
        } catch (_) {}

        return Right(optimisticUser);
      }

      final result = await remoteDataSource.resetAccount(userId: userId);
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
  ResultFuture<User> lockAccount({
    required String userId,
    required bool locked,
    String? reason,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.adminUser,
          operation: SyncOperation.update,
          payload: {
            'id': userId,
            'action': 'lock',
            'locked': locked,
            if (reason != null) 'reason': reason,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        // Read existing user to preserve all fields
        UserModel? existingUser;
        try {
          existingUser = await localDataSource.getCachedUser(userId);
        } on CacheException {
          // User not in cache — fall back to minimal optimistic
        }

        final optimisticUser = existingUser != null
            ? UserModel(
                id: existingUser.id,
                username: existingUser.username,
                fullName: existingUser.fullName,
                role: existingUser.role,
                accountStatus: locked ? 'locked' : 'activated',
                isActive: !locked,
                activatedAt: existingUser.activatedAt,
                createdAt: existingUser.createdAt,
              )
            : UserModel(
                id: userId,
                username: '',
                fullName: '(Unknown)',
                role: '',
                accountStatus: locked ? 'locked' : 'activated',
                isActive: !locked,
                activatedAt: null,
                createdAt: DateTime.now(),
              );

        try {
          await localDataSource.cacheAccounts([optimisticUser]);
        } catch (_) {}

        return Right(optimisticUser);
      }

      final result = await remoteDataSource.lockAccount(
        userId: userId,
        locked: locked,
        reason: reason,
      );
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
  ResultFuture<User> updateAccount({
    required String userId,
    String? fullName,
    String? role,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.adminUser,
          operation: SyncOperation.update,
          payload: {
            'id': userId,
            'action': 'update',
            if (fullName != null) 'full_name': fullName,
            if (role != null) 'role': role,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        // Read existing user to preserve all fields (fixes existing bug of returning blank user)
        UserModel? existingUser;
        try {
          existingUser = await localDataSource.getCachedUser(userId);
        } on CacheException {
          // User not in cache — fall back to minimal optimistic
        }

        final optimisticUser = existingUser != null
            ? UserModel(
                id: existingUser.id,
                username: existingUser.username,
                fullName: fullName ?? existingUser.fullName,
                role: role ?? existingUser.role,
                accountStatus: existingUser.accountStatus,
                isActive: existingUser.isActive,
                activatedAt: existingUser.activatedAt,
                createdAt: existingUser.createdAt,
              )
            : UserModel(
                id: userId,
                username: '',
                fullName: fullName ?? '',
                role: role ?? '',
                accountStatus: 'activated',
                isActive: true,
                activatedAt: null,
                createdAt: DateTime.now(),
              );

        // Update local cache with changed values
        try {
          await localDataSource.cacheAccounts([optimisticUser]);
        } catch (_) {}

        return Right(optimisticUser);
      }

      final result = await remoteDataSource.updateAccount(
        userId: userId,
        fullName: fullName,
        role: role,
      );
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
  ResultVoid deleteAccount({required String userId}) async {
    try {
      await remoteDataSource.deleteAccount(userId: userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Builds the list of optimistic [UserModel]s from pending sync queue entries.
  /// Includes both pending AND failed entries to prevent duplicate usernames.
  Future<List<UserModel>> _buildPendingAccounts() async {
    // Get all admin user creations (pending OR failed) to prevent queueing duplicates
    final entries = await syncQueue.getByEntityAndOperation(
      SyncEntityType.adminUser,
      SyncOperation.create,
    );
    final seenUsernames = <String>{};
    final result = <UserModel>[];
    for (final entry in entries) {
      final username = entry.payload['username'] as String? ?? '';
      if (seenUsernames.contains(username)) {
        continue;
      }
      seenUsernames.add(username);
      // Read id from payload; support both old 'local_id' and new 'id' field for backward compat
      final localId = (entry.payload['id'] ?? entry.payload['local_id']) as String? ?? '';
      result.add(UserModel(
        id: localId,
        username: username,
        fullName: entry.payload['full_name'] as String? ?? '',
        role: entry.payload['role'] as String? ?? '',
        accountStatus: 'pending_activation',
        isActive: false,
        activatedAt: null,
        createdAt: DateTime.now(),
      ));
    }
    return result;
  }
}