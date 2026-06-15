import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:uuid/uuid.dart';

ResultVoid deleteAssessment(
  AssessmentRepositoryBase base, {
  required String assessmentId,
}) async {
  try {
    if (!base.serverReachabilityService.isServerReachable) {
      await base.syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.assessment,
        operation: SyncOperation.delete,
        payload: {'id': assessmentId},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));
      await base.localDataSource.deleteAssessmentLocally(assessmentId: assessmentId);
      return const Right(null);
    }

    await base.remoteDataSource.deleteAssessment(assessmentId: assessmentId);
    await base.localDataSource.deleteAssessmentLocally(assessmentId: assessmentId);
    return const Right(null);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
