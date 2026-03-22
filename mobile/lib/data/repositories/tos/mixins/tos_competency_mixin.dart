import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import '../tos_repository_base.dart';

mixin TosCompetencyMixin on TosRepositoryBase {
  @override
  ResultFuture<TosCompetency> addCompetency({
    required String tosId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final id = const Uuid().v4();

      final model = CompetencyModel(
        id: id,
        tosId: tosId,
        competencyCode: data['competency_code'] as String?,
        competencyText: data['competency_text'] as String,
        daysTaught: (data['days_taught'] as num).toInt(),
        orderIndex: (data['order_index'] as num?)?.toInt() ?? 0,
        createdAt: now,
        updatedAt: now,
      );

      await localDataSource.saveCompetency(model);

      await syncQueue.enqueue(SyncQueueEntry(
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
        createdAt: DateTime.now(),
      ));

      return Right(model);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<TosCompetency> updateCompetency({
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

      // Return from cache (won't have updated fields in the entity since
      // updateCompetencyFields uses raw update — but the data is persisted)
      final competencies = await localDataSource.getCompetenciesByTos('');
      final updated = competencies.where((c) => c.id == competencyId).toList();
      if (updated.isNotEmpty) return Right(updated.first);

      // Fallback: construct a minimal entity
      return const Left(CacheFailure('Competency not found after update'));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultVoid deleteCompetency({required String competencyId}) async {
    try {
      await localDataSource.softDeleteCompetency(competencyId);

      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tosCompetency,
        operation: SyncOperation.delete,
        payload: {'id': competencyId},
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

  @override
  ResultFuture<List<TosCompetency>> bulkAddCompetencies({
    required String tosId,
    required List<Map<String, dynamic>> competencies,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final models = <CompetencyModel>[];

      for (var i = 0; i < competencies.length; i++) {
        final data = competencies[i];
        final id = const Uuid().v4();
        models.add(CompetencyModel(
          id: id,
          tosId: tosId,
          competencyCode: data['competency_code'] as String?,
          competencyText: data['competency_text'] as String,
          daysTaught: (data['days_taught'] as num).toInt(),
          orderIndex: (data['order_index'] as num?)?.toInt() ?? i,
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
}
