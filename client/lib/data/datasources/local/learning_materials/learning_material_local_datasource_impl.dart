import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'learning_material_local_datasource.dart';
import 'operations/learning_materials.dart' as ops;

class LearningMaterialLocalDataSourceImpl
    implements LearningMaterialLocalDataSource {
  final LocalDatabase localDatabase;
  final SyncQueue syncQueue;

  LearningMaterialLocalDataSourceImpl(this.localDatabase, this.syncQueue);

  @override
  Future<List<LearningMaterialModel>> getCachedMaterials(String classId) =>
      ops.getCachedMaterials(localDatabase, classId);

  @override
  Future<LearningMaterialModel> getCachedMaterialDetail(String materialId) =>
      ops.getCachedMaterialDetail(localDatabase, materialId);

  @override
  Future<List<MaterialFileModel>> getCachedMaterialFiles(String materialId) =>
      ops.getCachedMaterialFiles(localDatabase, materialId);

  @override
  Future<void> cacheMaterials(List<LearningMaterialModel> materials) =>
      ops.cacheMaterials(localDatabase, materials);

  @override
  Future<void> cacheMaterialDetail(LearningMaterialModel material) =>
      ops.cacheMaterialDetail(localDatabase, material);

  @override
  Future<void> cacheMaterialFiles(String materialId, List<MaterialFile> files) =>
      ops.cacheMaterialFiles(localDatabase, materialId, files);

  @override
  Future<void> reconcileDeletedMaterials(
    String classId,
    List<String> activeIds,
  ) =>
      ops.reconcileDeletedMaterials(localDatabase, classId, activeIds);

  @override
  Future<void> cacheFile(
    String fileId,
    String fileName,
    List<int> bytes,
  ) =>
      ops.cacheFile(localDatabase, fileId, fileName, bytes);

  @override
  Future<List<int>> getCachedFile(String fileId) =>
      ops.getCachedFile(localDatabase, fileId);

  @override
  Future<bool> isFileCached(String fileId) =>
      ops.isFileCached(localDatabase, fileId);

  @override
  Future<LearningMaterialModel> createMaterialLocally({
    required String classId,
    required String title,
    required String description,
    required String contentText,
  }) =>
      ops.createMaterialLocally(
        localDatabase,
        syncQueue,
        classId,
        title,
        description,
        contentText,
      );

  @override
  Future<void> updateMaterialLocally({
    required String materialId,
    required String title,
    required String description,
    required String contentText,
  }) =>
      ops.updateMaterialLocally(
        localDatabase,
        syncQueue,
        materialId,
        title,
        description,
        contentText,
      );

  @override
  Future<void> deleteMaterialLocally(String materialId) =>
      ops.deleteMaterialLocally(localDatabase, syncQueue, materialId);

  @override
  Future<void> stageMaterialFileForUpload({
    required String materialId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  }) =>
      ops.stageMaterialFileForUpload(
        localDatabase,
        syncQueue,
        materialId,
        fileName,
        fileType,
        fileSize,
        localPath,
      );

  @override
  Future<void> deleteMaterialFileLocally(String fileId) =>
      ops.deleteMaterialFileLocally(localDatabase, fileId);

  @override
  Future<void> clearAllCache() =>
      ops.clearAllCache(localDatabase);
}
