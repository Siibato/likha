import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:uuid/uuid.dart';

ResultVoid reorderAllAssessments(
  AssessmentRepositoryBase base, {
  required String classId,
  required List<String> assessmentIds,
}) async {
  try {
    if (!base.serverReachabilityService.isServerReachable) {
      for (int i = 0; i < assessmentIds.length; i++) {
        await base.syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assessment,
          operation: SyncOperation.update,
          payload: {'id': assessmentIds[i], 'order_index': i},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
      }
      return const Right(null);
    }
    for (int i = 0; i < assessmentIds.length; i++) {
      try {
        final (cached, _) = await base.localDataSource
            .getCachedAssessmentDetail(assessmentIds[i]);
        await base.localDataSource.cacheAssessments([
          AssessmentModel(
            id: cached.id,
            classId: cached.classId,
            title: cached.title,
            description: cached.description,
            timeLimitMinutes: cached.timeLimitMinutes,
            openAt: cached.openAt,
            closeAt: cached.closeAt,
            showResultsImmediately: cached.showResultsImmediately,
            resultsReleased: cached.resultsReleased,
            isPublished: cached.isPublished,
            orderIndex: i,
            totalPoints: cached.totalPoints,
            questionCount: cached.questionCount,
            submissionCount: cached.submissionCount,
            tosId: cached.tosId,
            gradingPeriodNumber: cached.gradingPeriodNumber,
            component: cached.component,
            createdAt: cached.createdAt,
            updatedAt: cached.updatedAt,
            cachedAt: cached.cachedAt,
            needsSync: cached.needsSync,
          ),
        ]);
      } catch (_) {}
    }
    await base.remoteDataSource.reorderAllAssessments(
      classId: classId,
      assessmentIds: assessmentIds,
    );
    return const Right(null);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
