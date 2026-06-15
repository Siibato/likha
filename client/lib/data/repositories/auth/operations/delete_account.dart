import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:uuid/uuid.dart';

ResultVoid deleteAccount(
  AuthLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String userId,
}) async {
  try {
    final now = DateTime.now();

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await txn.delete(
        DbTables.users,
        where: '${CommonCols.id} = ?',
        whereArgs: [userId],
      );

      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.adminUser,
          operation: SyncOperation.delete,
          payload: {'id': userId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return const Right(null);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
