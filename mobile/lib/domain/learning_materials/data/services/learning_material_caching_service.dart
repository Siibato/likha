import 'dart:async';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/domain/learning_materials/data/datasources/learning_material_local_datasource.dart';
import 'package:likha/domain/learning_materials/data/datasources/learning_material_remote_datasource.dart';
import 'package:likha/domain/learning_materials/data/models/learning_material_model.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';

/// Domain-specific caching service for learning materials.
///
/// Handles the special case where material detail returns MaterialDetail
/// but caching requires LearningMaterialModel.
class LearningMaterialCachingService {
  final LearningMaterialRemoteDataSource _remoteDataSource;
  final LearningMaterialLocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  LearningMaterialCachingService(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivityService,
  );

  /// Fetches materials for a class with online-first + cache fallback.
  Future<List<LearningMaterial>> getMaterials(String classId) async {
    if (_connectivityService.isOnline) {
      try {
        final result =
            await _remoteDataSource.getMaterials(classId: classId);
        // Fire-and-forget cache update
        unawaited(_localDataSource.cacheMaterials(result));
        return result;
      } on NetworkException catch (_) {
        // Flaky connection - fall through to cache
      } catch (e) {
        // ServerException or other errors bubble up
        rethrow;
      }
    }

    // Offline or network failure - use cached data
    return await _localDataSource.getCachedMaterials(classId);
  }

  /// Fetches material detail with online-first + cache fallback.
  ///
  /// Special handling: converts MaterialDetail to LearningMaterialModel
  /// for caching, then converts back for return.
  Future<MaterialDetail> getMaterialDetail(String materialId) async {
    if (_connectivityService.isOnline) {
      try {
        final result = await _remoteDataSource.getMaterialDetail(
          materialId: materialId,
        );
        // Fire-and-forget cache update - convert to model for caching
        unawaited(_localDataSource.cacheMaterialDetail(
          _materialDetailToModel(result),
        ));
        return result;
      } on NetworkException catch (_) {
        // Flaky connection - fall through to cache
      } catch (e) {
        // ServerException or other errors bubble up
        rethrow;
      }
    }

    // Offline or network failure - use cached data
    final cached = await _localDataSource.getCachedMaterialDetail(materialId);
    return _modelToMaterialDetail(cached);
  }

  /// Converts MaterialDetail to LearningMaterialModel for caching.
  LearningMaterialModel _materialDetailToModel(MaterialDetail detail) {
    return LearningMaterialModel(
      id: detail.id,
      classId: detail.classId,
      title: detail.title,
      description: detail.description,
      contentText: detail.contentText,
      orderIndex: detail.orderIndex,
      fileCount: detail.files.length,
      createdAt: detail.createdAt,
      updatedAt: detail.updatedAt,
    );
  }

  /// Converts LearningMaterialModel back to MaterialDetail with empty files.
  MaterialDetail _modelToMaterialDetail(LearningMaterialModel model) {
    return MaterialDetail(
      id: model.id,
      classId: model.classId,
      title: model.title,
      description: model.description,
      contentText: model.contentText,
      orderIndex: model.orderIndex,
      files: const [],
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
