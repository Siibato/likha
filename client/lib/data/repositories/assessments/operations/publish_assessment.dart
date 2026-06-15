import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';

ResultFuture<MutationResult<Assessment>> publishAssessment(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String assessmentId,
}) async {
  try {
    final (_, questions) = await localDataSource.getCachedAssessmentDetail(assessmentId);
    if (questions.isEmpty) {
      return const Left(ValidationFailure('Assessment must have at least one question to publish'));
    }

    final (cached, _) = await localDataSource.getCachedAssessmentDetail(assessmentId);
    final now = DateTime.now();

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
      isPublished: true,
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
      await localDataSource.markAssessmentPublished(assessmentId: assessmentId, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.publish,
          payload: {'id': assessmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } on ValidationException catch (e) {
    return Left(ValidationFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
