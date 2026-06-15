import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<User>> lockAccount(
  AuthLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String userId,
  required bool locked,
  String? reason,
}) async {
  try {
    final now = DateTime.now();

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
            fullName: existingUser.fullName,
            role: existingUser.role,
            accountStatus: locked ? 'locked' : 'activated',
            isActive: !locked,
            activatedAt: existingUser.activatedAt,
            createdAt: existingUser.createdAt,
            updatedAt: now,
            cachedAt: now,
            syncStatus: SyncStatus.pending,
          )
        : UserModel(
            id: userId,
            username: '',
            fullName: '(Unknown)',
            role: '',
            accountStatus: locked ? 'locked' : 'activated',
            isActive: !locked,
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
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return Right(MutationResult(entity: optimisticUser, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
