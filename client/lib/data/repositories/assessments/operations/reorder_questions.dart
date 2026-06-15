import 'package:dartz/dartz.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_write.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<void>> reorderQuestions(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AssessmentRemoteDataSource remoteDataSource, {
  required String assessmentId,
  required List<String> questionIds,
}) async {
  try {
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    try {
      for (int i = 0; i < questionIds.length; i++) {
        await localDataSource.updateQuestionOrder(
          questionId: questionIds[i],
          orderIndex: i,
        );
      }
    } catch (e) {
      return Left(ServerFailure('Failed to update question order: $e'));
    }

    try {
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.question,
          operation: SyncOperation.reorder,
          payload: {
            'assessment_id': assessmentId,
            'question_ids': questionIds,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to enqueue sync operation: $e'));
    }

    fireRemoteWrite<void>(
      remote: () => remoteDataSource.reorderAllQuestions(
        assessmentId: assessmentId,
        questionIds: questionIds,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (_) async {
        try {
          final db = await localDataSource.localDatabase.database;
          for (final id in questionIds) {
            await db.update(
              DbTables.assessmentQuestions,
              {CommonCols.syncStatus: SyncStatus.synced.dbValue},
              where: '${CommonCols.id} = ?',
              whereArgs: [id],
            );
          }
          await syncQueue.markSucceeded(queueEntryId);
        } catch (e) {
          // Ignore database_closed errors in fire-and-forget callbacks
          if (!e.toString().contains('database_closed')) {
            rethrow;
          }
        }
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }
        try {
          final db = await localDataSource.localDatabase.database;
          for (final id in questionIds) {
            await db.update(
              DbTables.assessmentQuestions,
              {CommonCols.syncStatus: SyncStatus.failed.dbValue},
              where: '${CommonCols.id} = ?',
              whereArgs: [id],
            );
          }
          await syncQueue.markFailed(queueEntryId, error.toString());
        } catch (e) {
          // Ignore database_closed errors in fire-and-forget callbacks
          if (!e.toString().contains('database_closed')) {
            rethrow;
          }
        }
      },
    );

    return const Right(MutationResult(
      entity: null,
      status: SyncStatus.pending,
    ));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
