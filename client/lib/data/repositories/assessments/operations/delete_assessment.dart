import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';

ResultFuture<MutationResult<void>> deleteAssessment(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String assessmentId,
}) async {
  try {
    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.deleteAssessment(assessmentId: assessmentId, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.delete,
          payload: {'id': assessmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ),
        txn: txn,
      );
    });

    return const Right(MutationResult(entity: null, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
