import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';

ResultFuture<MutationResult<Assessment>> updateAssessment(
  AssessmentLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String assessmentId,
  String? title,
  String? description,
  int? timeLimitMinutes,
  String? openAt,
  String? closeAt,
  bool? showResultsImmediately,
  int? gradingPeriodNumber,
  String? component,
}) async {
  try {
    final (cachedModel, _) = await localDataSource.getCachedAssessmentDetail(assessmentId);

    final now = DateTime.now();
    final optimisticModel = AssessmentModel(
      id: assessmentId,
      classId: cachedModel.classId,
      title: title ?? cachedModel.title,
      description: description ?? cachedModel.description,
      timeLimitMinutes: timeLimitMinutes ?? cachedModel.timeLimitMinutes,
      openAt: openAt != null ? DateTime.parse(openAt) : cachedModel.openAt,
      closeAt: closeAt != null ? DateTime.parse(closeAt) : cachedModel.closeAt,
      showResultsImmediately: showResultsImmediately ?? cachedModel.showResultsImmediately,
      resultsReleased: cachedModel.resultsReleased,
      isPublished: cachedModel.isPublished,
      orderIndex: cachedModel.orderIndex,
      totalPoints: cachedModel.totalPoints,
      questionCount: cachedModel.questionCount,
      submissionCount: cachedModel.submissionCount,
      tosId: cachedModel.tosId,
      gradingPeriodNumber: gradingPeriodNumber ?? cachedModel.gradingPeriodNumber,
      component: component ?? cachedModel.component,
      createdAt: cachedModel.createdAt,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      cachedAt: now,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.cacheAssessments(
        [optimisticModel],
        isServerConfirmed: false,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.update,
          payload: {
            'id': assessmentId,
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (timeLimitMinutes != null) 'time_limit_minutes': timeLimitMinutes,
            if (openAt != null) 'open_at': openAt,
            if (closeAt != null) 'close_at': closeAt,
            if (showResultsImmediately != null)
              'show_results_immediately': showResultsImmediately,
            if (gradingPeriodNumber != null) 'grading_period_number': gradingPeriodNumber,
            if (component != null) 'component': component,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
