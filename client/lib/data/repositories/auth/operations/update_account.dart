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

ResultFuture<User> updateAccount(
  ServerReachabilityService serverReachabilityService,
  AuthLocalDataSource localDataSource,
  AuthRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
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

    try {
      final cached = await localDataSource.getCachedAccounts();
      final updated = cached.map((a) {
        if (a.id == userId) {
          return UserModel(
            id: a.id,
            username: a.username,
            fullName: fullName ?? a.fullName,
            role: role ?? a.role,
            accountStatus: a.accountStatus,
            isActive: a.isActive,
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
