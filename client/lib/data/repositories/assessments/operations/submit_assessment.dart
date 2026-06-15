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

ResultFuture<MutationResult<SubmissionSummary>> submitAssessment(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AssessmentRemoteDataSource remoteDataSource, {
  required String submissionId,
}) async {
  try {
    final cached = await localDataSource.getCachedSubmissionDetail(submissionId);
    final assessmentId = cached?.assessmentId ?? '';

    double totalPoints = 0.0;
    try {
      final (assessment, _) = await localDataSource.getCachedAssessmentDetail(assessmentId);
      totalPoints = assessment.totalPoints.toDouble();
    } catch (_) {
      totalPoints = 0.0;
    }

    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();

    final payload = {
      'submission_id': submissionId,
      'assessment_id': assessmentId,
    };

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.submitAssessment(
        submissionId: submissionId,
        assessmentId: assessmentId,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.submit,
          payload: payload,
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    final optimisticModel = SubmissionSummary(
      id: submissionId,
      assessmentId: assessmentId,
      studentId: cached?.studentId ?? '',
      studentName: cached?.studentName ?? '',
      studentUsername: '',
      startedAt: cached?.startedAt ?? now,
      autoScore: cached?.autoScore ?? 0.0,
      finalScore: cached?.finalScore ?? 0.0,
      totalPoints: totalPoints,
      isSubmitted: true,
      syncStatus: SyncStatus.pending,
      submittedAt: now,
      cachedAt: now,
    );

    fireRemoteWrite<SubmissionSummaryModel>(
      remote: () => remoteDataSource.submitAssessment(
        submissionId: submissionId,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (serverResult) async {
        final db = await localDataSource.localDatabase.database;
        if (serverResult.id != submissionId) {
          await db.update(
            DbTables.assessmentSubmissions,
            {CommonCols.id: serverResult.id},
            where: '${CommonCols.id} = ?',
            whereArgs: [submissionId],
          );
        }
        await db.update(
          DbTables.assessmentSubmissions,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [serverResult.id],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.assessmentSubmissions,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [submissionId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
