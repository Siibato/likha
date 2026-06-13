import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:uuid/uuid.dart';
import '_helpers.dart' as helpers;

ResultFuture<User> createAccount(
  ServerReachabilityService serverReachabilityService,
  AuthLocalDataSource localDataSource,
  AuthRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
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
      final pendingAccounts = await helpers.buildPendingAccounts(syncQueue);
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

    try {
      final cached = await localDataSource.getCachedAccounts();
      final model = UserModel(
        id: result.id,
        username: result.username,
        fullName: result.fullName,
        role: result.role,
        accountStatus: result.accountStatus,
        isActive: result.isActive,
        activatedAt: result.activatedAt,
        createdAt: result.createdAt,
      );
      await localDataSource.cacheAccounts([model, ...cached]);
    } catch (_) {}

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
