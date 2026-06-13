import 'dart:io';

import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';

final Map<String, DateTime> lastBackgroundFetchTime = {};

String mimeType(String filePath) {
  final extension = filePath.split('.').last.toLowerCase();
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'doc':
    case 'docx':
      return 'application/msword';
    case 'xls':
    case 'xlsx':
      return 'application/vnd.ms-excel';
    case 'ppt':
    case 'pptx':
      return 'application/vnd.ms-powerpoint';
    case 'txt':
      return 'text/plain';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'zip':
      return 'application/zip';
    default:
      return 'application/octet-stream';
  }
}

Future<int> fileSize(String filePath) async {
  try {
    return await File(filePath).length();
  } catch (_) {
    return 0;
  }
}

void backgroundFetchMaterials(
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus,
  String classId,
) {
  Future.microtask(() async {
    try {
      RepoLogger.instance.log('_backgroundFetchMaterials() - Background fetch starting for classId=$classId');
      final fresh = await remoteDataSource.getMaterials(classId: classId);
      final List<LearningMaterial> cached;
      try {
        cached = await localDataSource.getCachedMaterials(classId);
      } on CacheException {
        await localDataSource.cacheMaterials(fresh);
        await localDataSource.reconcileDeletedMaterials(classId, fresh.map((m) => m.id).toList());
        for (final material in fresh) {
          if (material.fileCount > 0) {
            RepoLogger.instance.log('_backgroundFetchMaterials() - Fetching files for new material: ${material.id}');
            try {
              final detail = await remoteDataSource.getMaterialDetail(materialId: material.id);
              if (detail.files.isNotEmpty) {
                await localDataSource.cacheMaterialFiles(material.id, detail.files);
              }
            } catch (e) {
              RepoLogger.instance.warn('_backgroundFetchMaterials() - Failed to cache files for ${material.id}', e);
            }
          }
        }
        dataEventBus.notifyMaterialsChanged(classId);
        return;
      }
      if (materialsHaveChanged(cached, fresh)) {
        await localDataSource.cacheMaterials(fresh);
        await localDataSource.reconcileDeletedMaterials(classId, fresh.map((m) => m.id).toList());
        for (final material in fresh) {
          if (material.fileCount > 0) {
            RepoLogger.instance.log('_backgroundFetchMaterials() - Fetching files for updated material: ${material.id}');
            try {
              final detail = await remoteDataSource.getMaterialDetail(materialId: material.id);
              if (detail.files.isNotEmpty) {
                await localDataSource.cacheMaterialFiles(material.id, detail.files);
              }
            } catch (e) {
              RepoLogger.instance.warn('_backgroundFetchMaterials() - Failed to cache files for ${material.id}', e);
            }
          }
        }
        dataEventBus.notifyMaterialsChanged(classId);
      }
    } catch (e) {
      RepoLogger.instance.error('_backgroundFetchMaterials() - Error', e);
    }
  });
}

bool materialsHaveChanged(
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

void backgroundRefreshMaterialFiles(
  LearningMaterialLocalDataSource localDataSource,
  LearningMaterialRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus,
  String materialId,
  String classId,
) {
  Future.microtask(() async {
    try {
      RepoLogger.instance.log('_backgroundRefreshMaterialFiles() - Starting background refresh for materialId=$materialId, classId=$classId');
      final fresh = await remoteDataSource.getMaterialDetail(materialId: materialId);
      final cached = await localDataSource.getCachedMaterialFiles(materialId);

      RepoLogger.instance.log('_backgroundRefreshMaterialFiles() - cached files=${cached.length}, fresh files=${fresh.files.length}');

      if (materialFilesHaveChanged(cached, fresh.files)) {
        RepoLogger.instance.log('_backgroundRefreshMaterialFiles() - Files changed! Caching and notifying...');
        await localDataSource.cacheMaterialFiles(materialId, fresh.files);
        RepoLogger.instance.log('_backgroundRefreshMaterialFiles() - Calling dataEventBus.notifyMaterialsChanged($classId)');
        dataEventBus.notifyMaterialsChanged(classId);
      } else {
        RepoLogger.instance.log('_backgroundRefreshMaterialFiles() - Files unchanged, no notification');
      }
    } catch (e) {
      RepoLogger.instance.error('_backgroundRefreshMaterialFiles() - Error in background refresh', e);
    }
  });
}

bool materialFilesHaveChanged(
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
