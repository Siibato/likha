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

ResultFuture<LearningMaterial> updateMaterial(
  ServerReachabilityService serverReachabilityService,
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
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

    try {
      final updatedModel = LearningMaterialModel(
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
