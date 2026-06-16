import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<void>> deleteFile(
  AssignmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  {
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

    return const Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
