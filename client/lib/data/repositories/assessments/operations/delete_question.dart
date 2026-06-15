import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<void>> deleteQuestion(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AssessmentRemoteDataSource remoteDataSource, {
  required String questionId,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.deleteQuestion(questionId: questionId, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.question,
          operation: SyncOperation.delete,
          payload: {'id': questionId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<void>(
      remote: () => remoteDataSource.deleteQuestion(
        questionId: questionId,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (_) async {
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return const Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
