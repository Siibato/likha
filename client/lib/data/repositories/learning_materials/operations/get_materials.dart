import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import '_helpers.dart' as helpers;

final Map<String, DateTime> _lastFetch = {};

ResultFuture<List<LearningMaterial>> getMaterials(
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    try {
      final cachedMaterials = await localDataSource.getCachedMaterials(classId);

      if (!skipBackgroundRefresh) {
        final lastFetch = _lastFetch[classId];
        final now = DateTime.now();
        if (lastFetch == null || now.difference(lastFetch).inSeconds >= 2) {
          _lastFetch[classId] = now;
          fireRemoteFetch(
            dedupKey: 'materials/list/$classId/bg',
            remote: () => remoteDataSource.getMaterials(classId: classId),
            onSuccess: (fresh) async {
              try {
                final current = await localDataSource.getCachedMaterials(classId);
                if (helpers.materialsHaveChanged(current, fresh)) {
                  await localDataSource.cacheMaterials(fresh);
                  await localDataSource.reconcileDeletedMaterials(classId, fresh.map((m) => m.id).toList());
                  for (final material in fresh) {
                    if (material.fileCount > 0) {
                      try {
                        final detail = await remoteDataSource.getMaterialDetail(materialId: material.id);
                        if (detail.files.isNotEmpty) {
                          await localDataSource.cacheMaterialFiles(material.id, detail.files);
                        }
                      } catch (e) {
                        RepoLogger.instance.warn('getMaterials() - Failed to cache files for ${material.id}', e);
                      }
                    }
                  }
                  dataEventBus.notifyMaterialsChanged(classId);
                }
              } on CacheException {
                await localDataSource.cacheMaterials(fresh);
                await localDataSource.reconcileDeletedMaterials(classId, fresh.map((m) => m.id).toList());
                for (final material in fresh) {
                  if (material.fileCount > 0) {
                    try {
                      final detail = await remoteDataSource.getMaterialDetail(materialId: material.id);
                      if (detail.files.isNotEmpty) {
                        await localDataSource.cacheMaterialFiles(material.id, detail.files);
                      }
                    } catch (e) {
                      RepoLogger.instance.warn('getMaterials() - Failed to cache files for ${material.id}', e);
                    }
                  }
                }
                dataEventBus.notifyMaterialsChanged(classId);
              }
            },
          );
        }
      }

      return Right(cachedMaterials);
    } on CacheException {
      final freshMaterials = await remoteFetch(
        dedupKey: 'materials/list/$classId',
        remote: () => remoteDataSource.getMaterials(classId: classId),
      );
      await localDataSource.cacheMaterials(freshMaterials);

      for (final material in freshMaterials) {
        if (material.fileCount > 0) {
          try {
            final detail = await remoteDataSource.getMaterialDetail(materialId: material.id);
            if (detail.files.isNotEmpty) {
              await localDataSource.cacheMaterialFiles(material.id, detail.files);
            }
          } catch (e) {
            RepoLogger.instance.warn('getMaterials() - Failed to cache files for ${material.id}', e);
          }
        }
      }

      return Right(freshMaterials);
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
