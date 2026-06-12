import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:uuid/uuid.dart';

ResultVoid reorderQuestions(
  AssessmentRepositoryBase base, {
  required String assessmentId,
  required List<String> questionIds,
}) async {
  try {
    if (!base.serverReachabilityService.isServerReachable) {
      for (int i = 0; i < questionIds.length; i++) {
        await base.syncQueue.enqueue(SyncQueueEntry(
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
        await base.localDataSource.updateQuestionLocally(
          questionId: questionIds[i],
          updates: {'order_index': i},
          isOfflineMutation: false,
        );
      } catch (_) {}
    }
    await base.remoteDataSource.reorderAllQuestions(
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
