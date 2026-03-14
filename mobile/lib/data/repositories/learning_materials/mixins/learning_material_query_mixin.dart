import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/repositories/learning_materials/learning_material_repository_base.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';

mixin LearningMaterialQueryMixin on LearningMaterialRepositoryBase {
  final Map<String, DateTime> _lastBackgroundFetchTime = {};

  @override
  ResultFuture<List<LearningMaterial>> getMaterials({
    required String classId,
  }) async {
    try {
      try {
        final cachedMaterials = await localDataSource.getCachedMaterials(classId);

        // If server is reachable, fetch fresh in background (fire-and-forget)
        // But debounce: skip if we fetched this classId within the last 2 seconds
        if (serverReachabilityService.isServerReachable) {
          final lastFetch = _lastBackgroundFetchTime[classId];
          final now = DateTime.now();
          if (lastFetch == null || now.difference(lastFetch).inSeconds >= 2) {
            _lastBackgroundFetchTime[classId] = now;
            _backgroundFetchMaterials(classId);
          }
        }

        return Right(cachedMaterials);
      } on CacheException {
        // Cache empty — must fetch from server
        try {
          final freshMaterials = await remoteDataSource.getMaterials(classId: classId);
          await localDataSource.cacheMaterials(freshMaterials);

          // Also fetch and cache file details for materials with files
          print('[GET_MAT_INIT] 📥 Initial load: caching file details for ${freshMaterials.length} materials');
          for (final material in freshMaterials) {
            if (material.fileCount > 0) {
              print('[GET_MAT_INIT] 📄 Fetching files for material: ${material.id} (fileCount=${material.fileCount})');
              try {
                final detail = await remoteDataSource.getMaterialDetail(materialId: material.id);
                if (detail.files.isNotEmpty) {
                  await localDataSource.cacheMaterialFiles(material.id, detail.files);
                  print('[GET_MAT_INIT] ✅ Cached ${detail.files.length} files');
                }
              } catch (e) {
                print('[GET_MAT_INIT] ⚠️  Failed to cache files for ${material.id}: $e');
              }
            }
          }

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
  /// Also fetches and caches file details for materials with file_count > 0.
  /// Emits a DataEventBus event so the page can reload from updated cache.
  /// All errors are swallowed — users keep seeing stale cache without error.
  void _backgroundFetchMaterials(String classId) {
    Future.microtask(() async {
      try {
        print('[BG_FETCH_MAT] 🔄 Background fetch starting for classId=$classId');
        final fresh = await remoteDataSource.getMaterials(classId: classId);
        final List<LearningMaterial> cached;
        try {
          cached = await localDataSource.getCachedMaterials(classId);
        } on CacheException {
          await localDataSource.cacheMaterials(fresh);

          await localDataSource.reconcileDeletedMaterials(classId, fresh.map((m) => m.id).toList());

          for (final material in fresh) {
            if (material.fileCount > 0) {
              print('[BG_FETCH_MAT] 📄 Fetching files for new material: ${material.id}');
              try {
                final detail = await remoteDataSource.getMaterialDetail(materialId: material.id);
                if (detail.files.isNotEmpty) {
                  await localDataSource.cacheMaterialFiles(material.id, detail.files);
                }
              } catch (e) {
                print('[BG_FETCH_MAT] ⚠️  Failed to cache files for ${material.id}: $e');
              }
            }
          }

          dataEventBus.notifyMaterialsChanged(classId);
          return;
        }
        if (_materialsHaveChanged(cached, fresh)) {
          await localDataSource.cacheMaterials(fresh);

          await localDataSource.reconcileDeletedMaterials(classId, fresh.map((m) => m.id).toList());

          for (final material in fresh) {
            if (material.fileCount > 0) {
              print('[BG_FETCH_MAT] 📄 Fetching files for updated material: ${material.id}');
              try {
                final detail = await remoteDataSource.getMaterialDetail(materialId: material.id);
                if (detail.files.isNotEmpty) {
                  await localDataSource.cacheMaterialFiles(material.id, detail.files);
                }
              } catch (e) {
                print('[BG_FETCH_MAT] ⚠️  Failed to cache files for ${material.id}: $e');
              }
            }
          }

          dataEventBus.notifyMaterialsChanged(classId);
        }
      } catch (e) {
        print('[BG_FETCH_MAT] ❌ Error: $e');
      }
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
        print('[BG_REFRESH] 🔄 Starting background refresh for materialId=$materialId, classId=$classId');
        final fresh = await remoteDataSource.getMaterialDetail(materialId: materialId);
        final cached = await localDataSource.getCachedMaterialFiles(materialId);

        print('[BG_REFRESH] cached files=${cached.length}, fresh files=${fresh.files.length}');

        if (_materialFilesHaveChanged(cached, fresh.files)) {
          print('[BG_REFRESH] ✅ Files changed! Caching and notifying...');
          await localDataSource.cacheMaterialFiles(materialId, fresh.files);
          print('[BG_REFRESH] 📢 Calling dataEventBus.notifyMaterialsChanged($classId)');
          dataEventBus.notifyMaterialsChanged(classId);
        } else {
          print('[BG_REFRESH] ⚫ Files unchanged, no notification');
        }
      } catch (e) {
        print('[BG_REFRESH] ❌ Error in background refresh: $e');
      }
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