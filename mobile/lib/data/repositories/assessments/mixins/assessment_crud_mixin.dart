import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:uuid/uuid.dart';

mixin AssessmentCrudMixin on AssessmentRepositoryBase {
  @override
  ResultFuture<Assessment> createAssessment({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        final assessmentId = await localDataSource.createAssessmentLocally(
          classId: classId,
          title: title,
          description: description,
          timeLimitMinutes: timeLimitMinutes,
          openAt: openAt,
          closeAt: closeAt,
          showResultsImmediately: showResultsImmediately,
        );

        final now = DateTime.now();
        return Right(Assessment(
          id: assessmentId,
          classId: classId,
          title: title,
          description: description,
          timeLimitMinutes: timeLimitMinutes,
          openAt: DateTime.parse(openAt),
          closeAt: DateTime.parse(closeAt),
          showResultsImmediately: showResultsImmediately ?? false,
          resultsReleased: false,
          isPublished: false,
          totalPoints: 0,
          questionCount: 0,
          submissionCount: 0,
          createdAt: now,
          updatedAt: now,
        ));
      }

      final result = await remoteDataSource.createAssessment(
        classId: classId,
        data: {
          'title': title,
          if (description != null) 'description': description,
          'time_limit_minutes': timeLimitMinutes,
          'open_at': openAt,
          'close_at': closeAt,
          if (showResultsImmediately != null)
            'show_results_immediately': showResultsImmediately,
        },
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Assessment> updateAssessment({
    required String assessmentId,
    String? title,
    String? description,
    int? timeLimitMinutes,
    String? openAt,
    String? closeAt,
    bool? showResultsImmediately,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
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
          totalPoints: 0,
          questionCount: 0,
          submissionCount: 0,
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
      };

      final result = await remoteDataSource.updateAssessment(
        assessmentId: assessmentId,
        data: data,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid deleteAssessment({required String assessmentId}) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.delete,
          payload: {'id': assessmentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
        return const Right(null);
      }

      await remoteDataSource.deleteAssessment(assessmentId: assessmentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}