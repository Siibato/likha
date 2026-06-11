import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import '../learning_material_local_datasource_base.dart';
import 'operations/cache/cache_materials.dart';
import 'operations/cache/cache_material_detail.dart';
import 'operations/cache/cache_file.dart';
import 'operations/cache/get_cached_file.dart';
import 'operations/cache/is_file_cached.dart';
import 'operations/cache/cache_material_files.dart';
import 'operations/cache/reconcile_deleted_materials.dart';
import 'operations/cache/clear_all_cache.dart';

mixin LearningMaterialCacheMixin on LearningMaterialLocalDataSourceBase {
  @override
  Future<void> cacheMaterials(List<LearningMaterialModel> materials) async {
    return cacheMaterialsOp(localDatabase, materials);
  }

  @override
  Future<void> cacheMaterialDetail(LearningMaterialModel material) async {
    return cacheMaterialDetailOp(localDatabase, material);
  }

  @override
  Future<void> cacheFile(String fileId, String fileName, List<int> bytes) async {
    return cacheFileOp(localDatabase, fileId, fileName, bytes);
  }

  @override
  Future<List<int>> getCachedFile(String fileId) async {
    return getCachedFileOp(localDatabase, fileId);
  }

  @override
  Future<bool> isFileCached(String fileId) async {
    return isFileCachedOp(localDatabase, fileId);
  }

  @override
  Future<void> cacheMaterialFiles(String materialId, List<MaterialFile> files) async {
    return cacheMaterialFilesOp(localDatabase, materialId, files);
  }

  @override
  Future<void> reconcileDeletedMaterials(String classId, List<String> activeIds) async {
    return reconcileDeletedMaterialsOp(localDatabase, classId, activeIds);
  }

  @override
  Future<void> clearAllCache() async {
    return clearAllCacheOp(localDatabase);
  }
}