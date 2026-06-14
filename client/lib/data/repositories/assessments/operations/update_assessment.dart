import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultFuture<Assessment> updateAssessment(
  ServerReachabilityService serverReachabilityService,
AssessmentLocalDataSource localDataSource,
AssessmentRemoteDataSource remoteDataSource,
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
    if (!serverReachabilityService.isServerReachable) {
      Assessment? cached;
      try {
        final (cachedModel, _) =
            await localDataSource.getCachedAssessmentDetail(assessmentId);
        cached = Assessment(
          id: cachedModel.id,
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
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          cachedAt: cachedModel.cachedAt,
        );
      } catch (_) {}

      await syncQueue.enqueue(SyncQueueEntry(
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
        createdAt: DateTime.now(),
      ));

      if (cached != null) {
        return Right(cached);
      }

      return Right(Assessment(
        id: assessmentId,
        classId: '',
        title: title ?? '',
        description: description,
        timeLimitMinutes: timeLimitMinutes ?? 0,
        openAt: openAt != null ? DateTime.parse(openAt) : DateTime.now(),
        closeAt: closeAt != null ? DateTime.parse(closeAt) : DateTime.now(),
        showResultsImmediately: showResultsImmediately ?? false,
        resultsReleased: false,
        isPublished: false,
        orderIndex: 0,
        totalPoints: 0,
        questionCount: 0,
        submissionCount: 0,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    final data = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (timeLimitMinutes != null) 'time_limit_minutes': timeLimitMinutes,
      if (openAt != null) 'open_at': openAt,
      if (closeAt != null) 'close_at': closeAt,
      if (showResultsImmediately != null)
        'show_results_immediately': showResultsImmediately,
      if (gradingPeriodNumber != null) 'grading_period_number': gradingPeriodNumber,
      if (component != null) 'component': component,
    };

    final result = await remoteDataSource.updateAssessment(
      assessmentId: assessmentId,
      data: data,
    );
    await localDataSource.cacheAssessments([result]);
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
