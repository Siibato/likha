import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';

ResultVoid deleteGradeItem(
  GradingLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String id,
}) async {
  try {
    // Soft-delete locally
    await localDataSource.softDeleteItem(id);

    // Enqueue for sync
    await syncQueue.enqueue(SyncQueueEntry(
      id: const Uuid().v4(),
      entityType: SyncEntityType.gradeItem,
      operation: SyncOperation.delete,
      payload: {'id': id},
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
