import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

ResultFuture<TosCompetency> updateCompetency(
  TosLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String competencyId,
  required Map<String, dynamic> data,
}) async {
  try {
    await localDataSource.updateCompetencyFields(competencyId, data);

    await syncQueue.enqueue(SyncQueueEntry(
      id: const Uuid().v4(),
      entityType: SyncEntityType.tosCompetency,
      operation: SyncOperation.update,
      payload: {
        'id': competencyId,
        ...data,
      },
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 3,
      createdAt: DateTime.now(),
    ));

    // Return updated entity from cache
    final updated = await localDataSource.getCompetencyById(competencyId);
    if (updated != null) return Right(updated);

    return const Left(CacheFailure('Competency not found after update'));
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
