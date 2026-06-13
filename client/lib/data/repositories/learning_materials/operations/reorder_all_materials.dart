import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:uuid/uuid.dart';

ResultVoid reorderAllMaterials(
  ServerReachabilityService serverReachabilityService,
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
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

    try {
      final cached = await localDataSource.getCachedMaterials(classId);
      final reordered = cached.map((m) {
        final idx = materialIds.indexOf(m.id);
        if (idx == -1) return m;
        return LearningMaterialModel(
          id: m.id,
          classId: m.classId,
          title: m.title,
          description: m.description,
          contentText: m.contentText,
          orderIndex: idx,
          fileCount: m.fileCount,
          createdAt: m.createdAt,
          updatedAt: DateTime.now(),
        );
      }).toList();
      await localDataSource.cacheMaterials(reordered);
    } catch (_) {}

    return const Right(null);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
