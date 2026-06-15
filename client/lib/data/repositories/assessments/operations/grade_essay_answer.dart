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
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<SubmissionAnswer>> gradeEssayAnswer(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AssessmentRemoteDataSource remoteDataSource, {
  required String answerId,
  required double points,
}) async {
  try {
    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();

    final payload = {
      'answer_id': answerId,
      'points': points,
    };

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.gradeEssay(
        answerId: answerId,
        points: points,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.gradeEssay,
          payload: payload,
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    final optimisticModel = SubmissionAnswer(
      id: answerId,
      questionId: '',
      questionText: '',
      questionType: '',
      points: 0,
      pointsAwarded: points,
      isPendingEssayGrade: false,
    );

    fireRemoteWrite<SubmissionAnswerModel>(
      remote: () => remoteDataSource.gradeEssayAnswer(
        answerId: answerId,
        points: points,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (_) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.submissionAnswers,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [answerId],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.submissionAnswers,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [answerId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
