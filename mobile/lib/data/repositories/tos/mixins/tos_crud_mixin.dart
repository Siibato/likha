import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import '../tos_repository_base.dart';

mixin TosCrudMixin on TosRepositoryBase {
  @override
  ResultFuture<TableOfSpecifications> createTos({
    required String classId,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (serverReachabilityService.isServerReachable) {
        // Online: call server directly so the TOS exists on the server immediately
        final serverTos = await remoteDataSource.createTos(
          classId: classId,
          data: data,
        );
        await localDataSource.saveTos(serverTos);
        return Right(serverTos);
      }

      // Offline: optimistic local create + sync queue
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

      await localDataSource.saveTos(model);

      await syncQueue.enqueue(SyncQueueEntry(
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
        createdAt: DateTime.now(),
      ));

      return Right(model);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<TableOfSpecifications> updateTos({
    required String tosId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Update locally
      await localDataSource.updateTosFields(tosId, data);

      // Enqueue for sync
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tableOfSpecifications,
        operation: SyncOperation.update,
        payload: {
          'id': tosId,
          ...data,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));

      // Return updated entity from cache
      final updated = await localDataSource.getTosById(tosId);
      if (updated == null) {
        return const Left(CacheFailure('TOS not found after update'));
      }
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultVoid deleteTos({required String tosId}) async {
    try {
      // Soft-delete locally
      await localDataSource.softDeleteTos(tosId);

      // Enqueue for sync
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tableOfSpecifications,
        operation: SyncOperation.delete,
        payload: {'id': tosId},
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
}
