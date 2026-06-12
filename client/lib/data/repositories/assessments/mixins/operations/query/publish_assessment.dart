import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:uuid/uuid.dart';

ResultFuture<Assessment> publishAssessment(
  AssessmentRepositoryBase base, {
  required String assessmentId,
}) async {
  try {
    try {
      final (_, questions) =
          await base.localDataSource.getCachedAssessmentDetail(assessmentId);
      if (questions.isEmpty) {
        throw ValidationException(
            'Assessment must have at least one question to publish');
      }
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Cannot validate assessment: ${e.toString()}'));
    }

    if (!base.serverReachabilityService.isServerReachable) {
      await base.syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assessment,
        operation: SyncOperation.publish,
        payload: {'id': assessmentId},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));

      await base.localDataSource.markAssessmentPublishedLocally(assessmentId: assessmentId);

      try {
        final (cached, _) =
            await base.localDataSource.getCachedAssessmentDetail(assessmentId);
        return Right(Assessment(
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
          updatedAt: DateTime.now(),
          needsSync: true,
          cachedAt: cached.cachedAt,
        ));
      } catch (_) {
        return Right(Assessment(
          id: assessmentId,
          classId: '',
          title: '',
          description: null,
          timeLimitMinutes: 0,
          openAt: DateTime.now(),
          closeAt: DateTime.now(),
          showResultsImmediately: false,
          resultsReleased: false,
          isPublished: true,
          orderIndex: 0,
          totalPoints: 0,
          questionCount: 0,
          submissionCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }

    final result =
        await base.remoteDataSource.publishAssessment(assessmentId: assessmentId);
    await base.localDataSource.markAssessmentPublishedLocally(assessmentId: assessmentId);
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
