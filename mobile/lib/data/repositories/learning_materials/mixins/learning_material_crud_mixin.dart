import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/repositories/learning_materials/learning_material_repository_base.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:uuid/uuid.dart';

mixin LearningMaterialCrudMixin on LearningMaterialRepositoryBase {
  @override
  ResultFuture<LearningMaterial> createMaterial({
    required String classId,
    required String title,
    String? description,
    String? contentText,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        // Generate local UUID for offline creation
        final materialId = const Uuid().v4();

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.create,
          payload: {
            'class_id': classId,
            'title': title,
            if (description != null) 'description': description,
            if (contentText != null) 'content_text': contentText,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        final optimisticMaterial = LearningMaterial(
          id: materialId,
          classId: classId,
          title: title,
          description: description,
          contentText: contentText,
          orderIndex: 0,
          fileCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        try {
          final currentCached = await localDataSource.getCachedMaterials(classId);
          final optimisticModel = LearningMaterialModel(
            id: materialId,
            classId: classId,
            title: title,
            description: description,
            contentText: contentText,
            orderIndex: 0,
            fileCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await localDataSource.cacheMaterials([optimisticModel, ...currentCached]);
        } catch (_) {
          // If caching fails, still return the optimistic response
        }

        return Right(optimisticMaterial);
      }

      final result = await remoteDataSource.createMaterial(
        classId: classId,
        data: {
          'title': title,
          if (description != null) 'description': description,
          if (contentText != null) 'content_text': contentText,
        },
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<LearningMaterial> updateMaterial({
    required String materialId,
    String? title,
    String? description,
    String? contentText,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.update,
          payload: {
            'id': materialId,
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (contentText != null) 'content_text': contentText,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        // Fetch the current material from cache to preserve real values
        try {
          final existing = await localDataSource.getCachedMaterialDetail(materialId);
          return Right(LearningMaterial(
            id: existing.id,
            classId: existing.classId,
            title: title ?? existing.title,
            description: description ?? existing.description,
            contentText: contentText ?? existing.contentText,
            orderIndex: existing.orderIndex,
            fileCount: existing.fileCount,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
          ));
        } catch (_) {
          // If material not in cache, return stub
          return Right(LearningMaterial(
            id: materialId,
            classId: '',
            title: title ?? '',
            description: description,
            contentText: contentText,
            orderIndex: 0,
            fileCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      final result = await remoteDataSource.updateMaterial(
        materialId: materialId,
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (contentText != null) 'content_text': contentText,
        },
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid deleteMaterial({required String materialId}) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.delete,
          payload: {'id': materialId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
        return const Right(null);
      }

      await remoteDataSource.deleteMaterial(materialId: materialId);
      try {
        await localDataSource.deleteMaterialLocally(materialId);
      } catch (_) {
        // Non-critical: cleaned up on next sync
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<LearningMaterial> reorderMaterial({
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
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid reorderAllMaterials({
    required String classId,
    required List<String> materialIds,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        // Enqueue one update entry per material with its new order_index
        for (int i = 0; i < materialIds.length; i++) {
          await syncQueue.enqueue(SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.learningMaterial,
            operation: SyncOperation.update,
            payload: {'id': materialIds[i], 'order_index': i},
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: DateTime.now(),
          ));
        }
        return const Right(null);
      }

      await remoteDataSource.reorderAllMaterials(
        classId: classId,
        materialIds: materialIds,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}