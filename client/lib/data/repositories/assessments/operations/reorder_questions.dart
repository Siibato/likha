import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';

ResultFuture<MutationResult<void>> reorderQuestions(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String assessmentId,
  required List<String> questionIds,
}) async {
  try {
    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      for (int i = 0; i < questionIds.length; i++) {
        await localDataSource.updateQuestionOrder(
          questionId: questionIds[i],
          orderIndex: i,
          txn: txn,
        );
      }
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.question,
          operation: SyncOperation.reorder,
          payload: {
            'assessment_id': assessmentId,
            'question_ids': questionIds,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ),
        txn: txn,
      );
    });

    return const Right(MutationResult(
      entity: null,
      status: SyncStatus.pending,
    ));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
