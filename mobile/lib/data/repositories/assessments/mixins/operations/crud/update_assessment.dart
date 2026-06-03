import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:uuid/uuid.dart';

ResultFuture<Assessment> updateAssessment(
  AssessmentRepositoryBase base, {
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
    if (!base.serverReachabilityService.isServerReachable) {
      await base.syncQueue.enqueue(SyncQueueEntry(
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

    final result = await base.remoteDataSource.updateAssessment(
      assessmentId: assessmentId,
      data: data,
    );
    await base.localDataSource.cacheAssessments([result]);
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
