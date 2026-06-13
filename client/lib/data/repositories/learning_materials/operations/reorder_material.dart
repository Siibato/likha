import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:uuid/uuid.dart';

ResultFuture<LearningMaterial> reorderMaterial(
  ServerReachabilityService serverReachabilityService,
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String materialId,
  required int newOrderIndex,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.learningMaterial,
        operation: SyncOperation.update,
        payload: {
          'id': materialId,
          'order_index': newOrderIndex,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      ));

      return Right(LearningMaterial(
        id: materialId,
        classId: '',
        title: '',
        description: null,
        contentText: null,
        orderIndex: newOrderIndex,
        fileCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    final result = await remoteDataSource.reorderMaterial(
      materialId: materialId,
      newOrderIndex: newOrderIndex,
    );

    try {
      final existing = await localDataSource.getCachedMaterialDetail(materialId);
      final updatedModel = LearningMaterialModel(
        id: existing.id,
        classId: existing.classId,
        title: existing.title,
        description: existing.description,
        contentText: existing.contentText,
        orderIndex: newOrderIndex,
        fileCount: existing.fileCount,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );
      await localDataSource.cacheMaterials([updatedModel]);
    } catch (_) {}

    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
