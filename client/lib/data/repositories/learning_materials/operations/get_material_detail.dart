import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import '_helpers.dart' as helpers;

ResultFuture<MaterialDetail> getMaterialDetail(
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String materialId,
}) async {
  try {
    try {
      final cachedMaterial = await localDataSource.getCachedMaterialDetail(materialId);
      final cachedFiles = await localDataSource.getCachedMaterialFiles(materialId);

      fireRemoteFetch(
        dedupKey: 'materials/detail/$materialId/files/bg',
        remote: () => remoteDataSource.getMaterialDetail(materialId: materialId),
        onSuccess: (fresh) async {
          final currentFiles = await localDataSource.getCachedMaterialFiles(materialId);
          if (helpers.materialFilesHaveChanged(currentFiles, fresh.files)) {
            await localDataSource.cacheMaterialFiles(materialId, fresh.files);
            dataEventBus.notifyMaterialsChanged(cachedMaterial.classId);
          }
        },
      );

      return Right(MaterialDetail(
        id: cachedMaterial.id,
        classId: cachedMaterial.classId,
        title: cachedMaterial.title,
        description: cachedMaterial.description,
        contentText: cachedMaterial.contentText,
        orderIndex: cachedMaterial.orderIndex,
        files: cachedFiles,
        createdAt: cachedMaterial.createdAt,
        updatedAt: cachedMaterial.updatedAt,
        cachedAt: cachedMaterial.cachedAt,
        needsSync: cachedMaterial.needsSync,
      ));
    } on CacheException {
      final freshMaterial = await remoteFetch(
        dedupKey: 'materials/detail/$materialId',
        remote: () => remoteDataSource.getMaterialDetail(materialId: materialId),
      );

      if (freshMaterial.files.isNotEmpty) {
        try {
          await localDataSource.cacheMaterialFiles(materialId, freshMaterial.files);
        } catch (_) {
          // Ignore cache write errors — still return fresh data to user
        }
      }

      final detail = MaterialDetail(
        id: freshMaterial.id,
        classId: freshMaterial.classId,
        title: freshMaterial.title,
        description: freshMaterial.description,
        contentText: freshMaterial.contentText,
        orderIndex: freshMaterial.orderIndex,
        files: freshMaterial.files,
        createdAt: freshMaterial.createdAt,
        updatedAt: freshMaterial.updatedAt,
        cachedAt: null,
        needsSync: false,
      );
      return Right(detail);
    }
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
