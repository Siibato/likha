import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';

ResultFuture<MutationResult<SubmissionSummary>> submitAssessment(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue, {
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

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.submitAssessment(
        submissionId: submissionId,
        assessmentId: assessmentId,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessmentSubmission,
          operation: SyncOperation.submit,
          payload: {
            'submission_id': submissionId,
            'assessment_id': assessmentId,
          },
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

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
