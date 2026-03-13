import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/repositories/learning_materials/learning_material_repository_base.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';

mixin LearningMaterialQueryMixin on LearningMaterialRepositoryBase {
  @override
  ResultFuture<List<LearningMaterial>> getMaterials({
    required String classId,
  }) async {
    try {
      try {
        final cachedMaterials = await localDataSource.getCachedMaterials(classId);

        // If server is reachable, fetch fresh in background (fire-and-forget)
        if (serverReachabilityService.isServerReachable) {
          _backgroundFetchMaterials(classId);
        }

        return Right(cachedMaterials);
      } on CacheException {
        // Cache empty — must fetch from server
        try {
          final freshMaterials = await remoteDataSource.getMaterials(classId: classId);
          await localDataSource.cacheMaterials(freshMaterials);
          return Right(freshMaterials);
        } on NetworkException catch (e) {
          return Left(NetworkFailure(e.message));
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        }
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<MaterialDetail> getMaterialDetail({
    required String materialId,
  }) async {
    try {
      try {
        final cachedMaterial = await localDataSource.getCachedMaterialDetail(materialId);
        final cachedFiles = await localDataSource.getCachedMaterialFiles(materialId);

        // Background refresh of file metadata if server is reachable
        if (serverReachabilityService.isServerReachable) {
          _backgroundRefreshMaterialFiles(materialId, cachedMaterial.classId);
        }

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
        try {
          final freshMaterial = await remoteDataSource.getMaterialDetail(materialId: materialId);

          // Cache file metadata for future offline-capable reads
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
        } on NetworkException catch (e) {
          return Left(NetworkFailure(e.message));
        }
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Silently fetches fresh materials for [classId] from the server.
  /// Updates local cache only if any record has a newer [updatedAt].
  /// Emits a DataEventBus event so the page can reload from updated cache.
  /// All errors are swallowed — users keep seeing stale cache without error.
  void _backgroundFetchMaterials(String classId) {
    Future.microtask(() async {
      try {
        final fresh = await remoteDataSource.getMaterials(classId: classId);
        final List<LearningMaterial> cached;
        try {
          cached = await localDataSource.getCachedMaterials(classId);
        } on CacheException {
          await localDataSource.cacheMaterials(fresh);
          dataEventBus.notifyMaterialsChanged(classId);
          return;
        }
        if (_materialsHaveChanged(cached, fresh)) {
          await localDataSource.cacheMaterials(fresh);
          dataEventBus.notifyMaterialsChanged(classId);
        }
      } catch (_) {}
    });
  }

  bool _materialsHaveChanged(
    List<LearningMaterial> local,
    List<LearningMaterial> remote,
  ) {
    if (local.length != remote.length) return true;
    final localById = {for (final m in local) m.id: m};
    for (final r in remote) {
      final l = localById[r.id];
      if (l == null) return true;
      if (l.updatedAt.isBefore(r.updatedAt)) return true;
    }
    return false;
  }

  /// Silently refreshes file metadata for a specific material.
  /// Updates local cache only if files have changed.
  /// Emits a DataEventBus event so the detail page can reload if needed.
  /// All errors are swallowed.
  void _backgroundRefreshMaterialFiles(String materialId, String classId) {
    Future.microtask(() async {
      try {
        final fresh = await remoteDataSource.getMaterialDetail(materialId: materialId);
        final cached = await localDataSource.getCachedMaterialFiles(materialId);

        if (_materialFilesHaveChanged(cached, fresh.files)) {
          await localDataSource.cacheMaterialFiles(materialId, fresh.files);
          dataEventBus.notifyMaterialsChanged(classId);
        }
      } catch (_) {}
    });
  }

  bool _materialFilesHaveChanged(
    List<MaterialFile> cached,
    List<MaterialFile> fresh,
  ) {
    if (cached.length != fresh.length) return true;
    final cachedIds = {for (final f in cached) f.id};
    for (final f in fresh) {
      if (!cachedIds.contains(f.id)) return true;
    }
    return false;
  }
}