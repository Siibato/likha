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
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<Assessment>> unpublishAssessment(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue,
  AssessmentRemoteDataSource remoteDataSource, {
  required String assessmentId,
}) async {
  try {
    final (cached, _) = await localDataSource.getCachedAssessmentDetail(assessmentId);
    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();

    final optimisticModel = AssessmentModel(
      id: cached.id,
      classId: cached.classId,
      title: cached.title,
      description: cached.description,
      timeLimitMinutes: cached.timeLimitMinutes,
      openAt: cached.openAt,
      closeAt: cached.closeAt,
      showResultsImmediately: cached.showResultsImmediately,
      resultsReleased: cached.resultsReleased,
      isPublished: false,
      orderIndex: cached.orderIndex,
      totalPoints: cached.totalPoints,
      questionCount: cached.questionCount,
      submissionCount: cached.submissionCount,
      tosId: cached.tosId,
      gradingPeriodNumber: cached.gradingPeriodNumber,
      component: cached.component,
      createdAt: cached.createdAt,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      cachedAt: now,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.markAssessmentUnpublished(assessmentId: assessmentId, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.unpublish,
          payload: {'id': assessmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    fireRemoteWrite<AssessmentModel>(
      remote: () => remoteDataSource.unpublishAssessment(
        assessmentId: assessmentId,
        idempotencyKey: queueEntryId,
      ),
      onSuccess: (_) async {
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.assessments,
          {CommonCols.syncStatus: SyncStatus.synced.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [assessmentId],
        );
        await syncQueue.markSucceeded(queueEntryId);
      },
      onError: (error) async {
        if (error is NetworkException) {
          return;
        }
        final db = await localDataSource.localDatabase.database;
        await db.update(
          DbTables.assessments,
          {CommonCols.syncStatus: SyncStatus.failed.dbValue},
          where: '${CommonCols.id} = ?',
          whereArgs: [assessmentId],
        );
        await syncQueue.markFailed(queueEntryId, error.toString());
      },
    );

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
