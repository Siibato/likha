import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

ResultFuture<MutationResult<TosCompetency>> addCompetency(
  TosLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String tosId,
  required Map<String, dynamic> data,
}) async {
  try {
    final now = DateTime.now();
    final id = const Uuid().v4();

    final model = CompetencyModel(
      id: id,
      tosId: tosId,
      competencyCode: data['competency_code'] as String?,
      competencyText: data['competency_text'] as String,
      timeUnitsTaught: (data['time_units_taught'] as num?)?.toInt() ?? (data['days_taught'] as num).toInt(),
      orderIndex: (data['order_index'] as num?)?.toInt() ?? 0,
      easyCount: data['easy_count'] as int?,
      mediumCount: data['medium_count'] as int?,
      hardCount: data['hard_count'] as int?,
      createdAt: now,
      updatedAt: now,
    );

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.saveCompetency(model, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.tosCompetency,
          operation: SyncOperation.create,
          payload: {
            'id': id,
            'tos_id': tosId,
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
