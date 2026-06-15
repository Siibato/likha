import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<void>> deleteFile(
  AssignmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AssignmentRemoteDataSource remoteDataSource, {
  required String fileId,
}) async {
  try {
    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();
    final db = await localDataSource.localDatabase.database;

    await db.transaction((txn) async {
      await localDataSource.softDeleteSubmissionFile(fileId, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.submissionFile,
          operation: SyncOperation.delete,
          payload: {'file_id': fileId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<void>(
      remote: () => remoteDataSource.deleteFile(
        fileId: fileId,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (_) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.submissionFiles,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [fileId],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.submissionFiles,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [fileId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return const Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
