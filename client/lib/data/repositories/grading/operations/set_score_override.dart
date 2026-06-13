import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';

ResultVoid setScoreOverride(
  GradingLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String scoreId,
  required double overrideScore,
}) async {
  try {
    // Update locally
    await localDataSource.updateScoreOverride(scoreId, overrideScore);

    // Enqueue for sync
    await syncQueue.enqueue(SyncQueueEntry(
      id: const Uuid().v4(),
      entityType: SyncEntityType.gradeScore,
      operation: SyncOperation.setOverride,
      payload: {
        'score_id': scoreId,
        'override_score': overrideScore,
      },
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 3,
      createdAt: DateTime.now(),
    ));

    return const Right(null);
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
