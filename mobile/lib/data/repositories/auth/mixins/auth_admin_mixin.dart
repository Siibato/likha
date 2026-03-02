import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
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
    try {
      if (!serverReachabilityService.isServerReachable) {
        final pendingAccounts = await _buildPendingAccounts();
        if (pendingAccounts.any((a) => a.username.toLowerCase() == username.toLowerCase())) {
          return Left(ServerFailure('Account "$username" is already being created. Please wait for sync.'));
        }

        try {
          final cachedAccounts = await localDataSource.getCachedAccounts();
          if (cachedAccounts.any((a) => a.username.toLowerCase() == username.toLowerCase())) {
            return Left(ServerFailure('Account "$username" already exists.'));
          }
        } on CacheException {
        }

        await syncQueue.enqueue(SyncQueueEntry(
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
        ));

        final optimisticUser = UserModel(
          id: '',
          username: username,
          fullName: fullName,
          role: role,
          accountStatus: 'pending_activation',
          isActive: false,
          activatedAt: null,
          createdAt: DateTime.now(),
        );

        try {
          await localDataSource.cacheCreatedAccount(optimisticUser);
        } catch (e) {
          // Cache failure is not critical
        }

        return Right(optimisticUser);
      }

      final result = await remoteDataSource.createAccount(
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
      var cachedAccounts = <UserModel>[];
      bool hasCachedData = false;

      try {
        cachedAccounts = await localDataSource.getCachedAccounts();
        print(cachedAccounts);
        hasCachedData = true;
      } on CacheException {
        hasCachedData = false;
      }

      if (serverReachabilityService.isServerReachable) {
        try {
          final freshAccounts = await remoteDataSource.getAllAccounts();
          await localDataSource.cacheAccounts(freshAccounts);

          final pendingAccounts = await _buildPendingAccounts();
          // Final dedup: remove pending accounts that already exist in server accounts
          final serverUsernames = freshAccounts.map((a) => a.username).toSet();
          final deduped = pendingAccounts
              .where((p) => !serverUsernames.contains(p.username))
              .toList();
          return Right([...freshAccounts, ...deduped]);
        } catch (e) {
          if (!hasCachedData) {
            if (e is ServerException) return Left(ServerFailure(e.message));
            if (e is NetworkException) return Left(NetworkFailure(e.message));
            return Left(ServerFailure(e.toString()));
          }
          // Has cache — fall through
        }
      }

      final pendingAccounts = await _buildPendingAccounts();

      if (hasCachedData) {
        // Final dedup: remove pending accounts that already exist in cached accounts
        final cachedUsernames = cachedAccounts.map((a) => a.username).toSet();
        final deduped = pendingAccounts
            .where((p) => !cachedUsernames.contains(p.username))
            .toList();
        return Right([...cachedAccounts, ...deduped]);
      }

      if (pendingAccounts.isNotEmpty) {
        return Right(pendingAccounts);
      }

      return const Left(NetworkFailure('No internet connection and no cached data'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
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

      final result = await remoteDataSource.resetAccount(userId: userId);
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
  ResultFuture<User> lockAccount({
    required String userId,
    required bool locked,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.adminUser,
          operation: SyncOperation.update,
          payload: {'id': userId, 'action': 'lock', 'locked': locked},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

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

      final result = await remoteDataSource.lockAccount(
        userId: userId,
        locked: locked,
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
  ResultFuture<User> updateAccount({
    required String userId,
    String? username,
    String? fullName,
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
            if (username != null) 'username': username,
            if (fullName != null) 'full_name': fullName,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

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

      final result = await remoteDataSource.updateAccount(
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

  /// Builds the list of optimistic [UserModel]s from pending sync queue entries.
  Future<List<UserModel>> _buildPendingAccounts() async {
    final pendingEntries = await syncQueue.getAllRetriable();
    final seenUsernames = <String>{};
    final result = <UserModel>[];
    for (final entry in pendingEntries) {
      if (entry.entityType != SyncEntityType.adminUser ||
          entry.operation != SyncOperation.create) {
        continue;
      }
      final username = entry.payload['username'] as String? ?? '';
      if (seenUsernames.contains(username)) {
        continue;
      }
      seenUsernames.add(username);
      result.add(UserModel(
        id: '',
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