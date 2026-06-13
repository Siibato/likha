import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

ResultFuture<List<TosCompetency>> bulkAddCompetencies(
  TosLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String tosId,
  required List<Map<String, dynamic>> competencies,
}) async {
  try {
    final now = DateTime.now();
    final models = <CompetencyModel>[];

    for (var i = 0; i < competencies.length; i++) {
      final data = competencies[i];
      final id = const Uuid().v4();
      models.add(CompetencyModel(
        id: id,
        tosId: tosId,
        competencyCode: data['competency_code'] as String?,
        competencyText: data['competency_text'] as String,
        timeUnitsTaught: (data['time_units_taught'] as num?)?.toInt() ?? (data['days_taught'] as num).toInt(),
        orderIndex: (data['order_index'] as num?)?.toInt() ?? i,
        easyCount: data['easy_count'] as int?,
        mediumCount: data['medium_count'] as int?,
        hardCount: data['hard_count'] as int?,
        createdAt: now,
        updatedAt: now,
      ));
    }

    await localDataSource.bulkSaveCompetencies(models);

    // Enqueue each competency for sync
    for (var i = 0; i < models.length; i++) {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tosCompetency,
        operation: SyncOperation.create,
        payload: {
          'id': models[i].id,
          'tos_id': tosId,
          ...competencies[i],
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));
    }

    return Right(models);
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
