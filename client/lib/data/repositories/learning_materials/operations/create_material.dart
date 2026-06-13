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

ResultFuture<LearningMaterial> createMaterial(
  ServerReachabilityService serverReachabilityService,
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
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
          'id': materialId,
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

    try {
      final cached = await localDataSource.getCachedMaterials(classId);
      final model = LearningMaterialModel(
        id: result.id,
        classId: result.classId,
        title: result.title,
        description: result.description,
        contentText: result.contentText,
        orderIndex: result.orderIndex,
        fileCount: result.fileCount,
        createdAt: result.createdAt,
        updatedAt: result.updatedAt,
      );
      await localDataSource.cacheMaterials([model, ...cached]);
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
