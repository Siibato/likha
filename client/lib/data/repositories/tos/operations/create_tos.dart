import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

ResultFuture<MutationResult<TableOfSpecifications>> createTos(
  TosLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required Map<String, dynamic> data,
}) async {
  try {
    final now = DateTime.now();
    final id = const Uuid().v4();

    final model = TosModel(
      id: id,
      classId: classId,
      gradingPeriodNumber: (data['grading_period_number'] as num?)?.toInt() ?? (data['quarter'] as num).toInt(),
      title: data['title'] as String,
      classificationMode: data['classification_mode'] as String,
      totalItems: (data['total_items'] as num).toInt(),
      timeUnit: data['time_unit'] as String? ?? 'days',
      easyPercentage: (data['easy_percentage'] as num?)?.toDouble() ?? 50.0,
      mediumPercentage: (data['medium_percentage'] as num?)?.toDouble() ?? 30.0,
      hardPercentage: (data['hard_percentage'] as num?)?.toDouble() ?? 20.0,
      createdAt: now,
      updatedAt: now,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.saveTos(model, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.tableOfSpecifications,
          operation: SyncOperation.create,
          payload: {
            'id': id,
            'class_id': classId,
            ...data,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return Right(MutationResult(entity: model, status: SyncStatus.pending));
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
