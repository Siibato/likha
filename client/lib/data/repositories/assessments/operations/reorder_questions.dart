import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultVoid reorderQuestions(
  ServerReachabilityService serverReachabilityService,
AssessmentLocalDataSource localDataSource,
AssessmentRemoteDataSource remoteDataSource,
SyncQueue syncQueue, {
  required String assessmentId,
  required List<String> questionIds,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      for (int i = 0; i < questionIds.length; i++) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.question,
          operation: SyncOperation.update,
          payload: {'id': questionIds[i], 'order_index': i},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
      }
      return const Right(null);
    }
    for (int i = 0; i < questionIds.length; i++) {
      try {
        await localDataSource.updateQuestion(
          questionId: questionIds[i],
          updates: {'order_index': i},
          isOfflineMutation: false,
        );
      } catch (_) {}
    }
    await remoteDataSource.reorderAllQuestions(
      assessmentId: assessmentId,
      questionIds: questionIds,
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
