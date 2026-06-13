import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:uuid/uuid.dart';

ResultFuture<User> lockAccount(
  ServerReachabilityService serverReachabilityService,
  AuthLocalDataSource localDataSource,
  AuthRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
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

    try {
      final cached = await localDataSource.getCachedAccounts();
      final updated = cached.map((a) {
        if (a.id == userId) {
          return UserModel(
            id: a.id,
            username: a.username,
            fullName: a.fullName,
            role: a.role,
            accountStatus: locked ? 'locked' : 'activated',
            isActive: !locked,
            activatedAt: a.activatedAt,
            createdAt: a.createdAt,
          );
        }
        return a;
      }).toList();
      await localDataSource.cacheAccounts(updated);
    } catch (_) {}

    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
