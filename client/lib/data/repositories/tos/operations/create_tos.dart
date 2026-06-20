import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<TableOfSpecifications>> createTos(
  TosLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required Map<String, dynamic> data,
}) async {
  try {
    final tosId = const Uuid().v4();
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final optimisticModel = TosModel(
      id: tosId,
      classId: classId,
      termNumber: (data['term_number'] as num?)?.toInt() ?? (data['quarter'] as num).toInt(),
      title: data['title'] as String,
      classificationMode: data['classification_mode'] as String,
      totalItems: (data['total_items'] as num).toInt(),
      timeUnit: data['time_unit'] as String? ?? 'days',
      easyPercentage: (data['easy_percentage'] as num?)?.toDouble() ?? 50.0,
      mediumPercentage: (data['medium_percentage'] as num?)?.toDouble() ?? 30.0,
      hardPercentage: (data['hard_percentage'] as num?)?.toDouble() ?? 20.0,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.saveTos(optimisticModel, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.tableOfSpecifications,
          operation: SyncOperation.create,
          payload: optimisticModel.toPayload(),
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return Right(MutationResult(entity: optimisticModel, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
