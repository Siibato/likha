import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<User>> updateAccount(
  AuthLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AuthRemoteDataSource remoteDataSource, {
  required String userId,
  String? fullName,
  String? role,
}) async {
  try {
    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();

    UserModel? existingUser;
    try {
      existingUser = await localDataSource.getCachedUser(userId);
    } catch (_) {
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
            updatedAt: now,
            cachedAt: now,
            syncStatus: SyncStatus.pending,
          )
        : UserModel(
            id: userId,
            username: '',
            fullName: fullName ?? '',
            role: role ?? '',
            accountStatus: 'activated',
            isActive: true,
            activatedAt: null,
            createdAt: now,
            updatedAt: now,
            cachedAt: now,
            syncStatus: SyncStatus.pending,
          );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      final map = optimisticUser.toMap();
      map[CommonCols.cachedAt] = now.toIso8601String();
      map[CommonCols.syncStatus] = SyncStatus.pending.dbValue;
      await txn.update(
        DbTables.users,
        map,
        where: '${CommonCols.id} = ?',
        whereArgs: [userId],
      );

      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
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
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<UserModel>(
      remote: () => remoteDataSource.updateAccount(
        userId: userId,
        fullName: fullName,
        role: role,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverModel) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.users,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [serverModel.id],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.users,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [userId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: optimisticUser, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
