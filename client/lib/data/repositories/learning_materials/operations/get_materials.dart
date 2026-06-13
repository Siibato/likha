import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import '_helpers.dart' as helpers;

ResultFuture<List<LearningMaterial>> getMaterials(
  ServerReachabilityService serverReachabilityService,
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
}) async {
  try {
    try {
      final cachedMaterials = await localDataSource.getCachedMaterials(classId);

      // If server is reachable, fetch fresh in background (fire-and-forget)
      // But debounce: skip if we fetched this classId within the last 2 seconds
      if (serverReachabilityService.isServerReachable) {
        final lastFetch = helpers.lastBackgroundFetchTime[classId];
        final now = DateTime.now();
        if (lastFetch == null || now.difference(lastFetch).inSeconds >= 2) {
          helpers.lastBackgroundFetchTime[classId] = now;
          helpers.backgroundFetchMaterials(localDataSource, remoteDataSource, dataEventBus, classId);
        }
      }

      return Right(cachedMaterials);
    } on CacheException {
      // Cache empty — must fetch from server
      try {
        final freshMaterials = await remoteDataSource.getMaterials(classId: classId);
        await localDataSource.cacheMaterials(freshMaterials);

        // Also fetch and cache file details for materials with files
        RepoLogger.instance.log('getMaterials() - Initial load: caching file details for ${freshMaterials.length} materials');
        for (final material in freshMaterials) {
          if (material.fileCount > 0) {
            RepoLogger.instance.log('getMaterials() - Fetching files for material: ${material.id} (fileCount=${material.fileCount})');
            try {
              final detail = await remoteDataSource.getMaterialDetail(materialId: material.id);
              if (detail.files.isNotEmpty) {
                await localDataSource.cacheMaterialFiles(material.id, detail.files);
                RepoLogger.instance.log('getMaterials() - Cached ${detail.files.length} files');
              }
            } catch (e) {
              RepoLogger.instance.warn('getMaterials() - Failed to cache files for ${material.id}', e);
            }
          }
        }

        return Right(freshMaterials);
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, statusCode: e.statusCode));
      }
    }
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
