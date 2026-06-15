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
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<User>> createAccount(
  AuthLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AuthRemoteDataSource remoteDataSource, {
  required String username,
  required String fullName,
  required String role,
}) async {
  try {
    final now = DateTime.now();
    final userId = const Uuid().v4();
    final queueEntryId = const Uuid().v4();

    final optimisticUser = UserModel(
      id: userId,
      username: username,
      fullName: fullName,
      role: role,
      accountStatus: 'pending_activation',
      isActive: false,
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
      await txn.insert(
        DbTables.users,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.adminUser,
          operation: SyncOperation.create,
          payload: optimisticUser.toPayload(),
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<UserModel>(
      remote: () => remoteDataSource.createAccount(
        username: username,
        fullName: fullName,
        role: role,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverModel) async {
        final db = await localDataSource.localDatabase.database;

        if (serverModel.id != userId) {
          await db.update(
            DbTables.users,
            {CommonCols.id: serverModel.id},
            where: '${CommonCols.id} = ?',
            whereArgs: [userId],
          );
        }

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
