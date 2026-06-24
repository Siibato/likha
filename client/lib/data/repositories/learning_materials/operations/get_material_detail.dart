import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import '_helpers.dart' as helpers;

bool _materialDetailHasChanged(
  MaterialDetail current,
  MaterialDetail fresh,
) {
  if (current.title != fresh.title) return true;
  if (current.description != fresh.description) return true;
  if (current.contentText != fresh.contentText) return true;
  if (current.orderIndex != fresh.orderIndex) return true;
  if (current.updatedAt != fresh.updatedAt) return true;
  if (helpers.materialFilesHaveChanged(current.files, fresh.files)) return true;
  return false;
}

ResultFuture<MaterialDetail> getMaterialDetail(
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource, {
  required String materialId,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cachedMaterial = await localDataSource.getCachedMaterialDetail(materialId);
      final cachedFiles = await localDataSource.getCachedMaterialFiles(materialId);
      final cachedDetail = MaterialDetail(
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
      );

      if (!skipBackgroundRefresh) {
        fireRemoteFetch(
          dedupKey: 'materials/detail/$materialId/bg',
          remote: () => remoteDataSource.getMaterialDetail(materialId: materialId),
          onSuccess: (fresh) async {
            final currentMaterial = await localDataSource.getCachedMaterialDetail(materialId);
            final currentFiles = await localDataSource.getCachedMaterialFiles(materialId);
            final currentDetail = MaterialDetail(
              id: currentMaterial.id,
              classId: currentMaterial.classId,
              title: currentMaterial.title,
              description: currentMaterial.description,
              contentText: currentMaterial.contentText,
              orderIndex: currentMaterial.orderIndex,
              files: currentFiles,
              createdAt: currentMaterial.createdAt,
              updatedAt: currentMaterial.updatedAt,
              cachedAt: currentMaterial.cachedAt,
            );
            if (_materialDetailHasChanged(currentDetail, fresh)) {
              await localDataSource.cacheMaterialDetail(
                LearningMaterialModel(
                  id: fresh.id,
                  classId: fresh.classId,
                  title: fresh.title,
                  description: fresh.description,
                  contentText: fresh.contentText,
                  orderIndex: fresh.orderIndex,
                  fileCount: fresh.files.length,
                  createdAt: fresh.createdAt,
                  updatedAt: fresh.updatedAt,
                  cachedAt: DateTime.now(),
                  syncStatus: SyncStatus.synced,
                ),
              );
              await localDataSource.cacheMaterialFiles(materialId, fresh.files);
            }
          },
        );
      }

      return Right(cachedDetail);
    } on CacheException {
      final freshMaterial = await remoteFetch(
        dedupKey: 'materials/detail/$materialId',
        remote: () => remoteDataSource.getMaterialDetail(materialId: materialId),
      );

      try {
        await localDataSource.cacheMaterialDetail(
          LearningMaterialModel(
            id: freshMaterial.id,
            classId: freshMaterial.classId,
            title: freshMaterial.title,
            description: freshMaterial.description,
            contentText: freshMaterial.contentText,
            orderIndex: freshMaterial.orderIndex,
            fileCount: freshMaterial.files.length,
            createdAt: freshMaterial.createdAt,
            updatedAt: freshMaterial.updatedAt,
            cachedAt: DateTime.now(),
            syncStatus: SyncStatus.synced,
          ),
        );
        if (freshMaterial.files.isNotEmpty) {
          await localDataSource.cacheMaterialFiles(materialId, freshMaterial.files);
        }
      } catch (_) {
        // Ignore cache write errors — still return fresh data to user
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
