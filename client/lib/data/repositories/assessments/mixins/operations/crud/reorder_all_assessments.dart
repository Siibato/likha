import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
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
