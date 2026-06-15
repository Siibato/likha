import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'operations/learning_materials.dart' as ops;

abstract class LearningMaterialLocalDataSource {
  LocalDatabase get localDatabase;

  Future<List<LearningMaterialModel>> getCachedMaterials(String classId);
  Future<LearningMaterialModel> getCachedMaterialDetail(String materialId);
  Future<List<MaterialFileModel>> getCachedMaterialFiles(String materialId);
  Future<void> cacheMaterials(List<LearningMaterialModel> materials, {Transaction? txn});
  Future<void> cacheMaterialDetail(LearningMaterialModel material);
  Future<void> cacheMaterialFiles(String materialId, List<MaterialFile> files);
  Future<void> reconcileDeletedMaterials(String classId, List<String> activeIds);
  Future<void> cacheFile(String fileId, String fileName, List<int> bytes);
  Future<List<int>> getCachedFile(String fileId);
  Future<bool> isFileCached(String fileId);
  Future<LearningMaterialModel> createMaterialLocally({
    required String classId,
    required String title,
    required String description,
    required String contentText,
    Transaction? txn,
  });
  Future<void> updateMaterialLocally({
    required String materialId,
    required String title,
    required String description,
    required String contentText,
    Transaction? txn,
  });
  Future<void> deleteMaterialLocally(String materialId, {Transaction? txn});
  Future<String> stageMaterialFileForUpload({
    required String materialId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
    required String fileId,
    Transaction? txn,
  });
  Future<void> deleteMaterialFileLocally(String fileId, {Transaction? txn});
  Future<void> saveMaterial(LearningMaterialModel material, {Transaction? txn});
  Future<void> updateMaterialFields(String materialId, Map<String, dynamic> data, {Transaction? txn});
  Future<void> softDeleteMaterial(String materialId, {Transaction? txn});
  Future<void> saveMaterialOrder(String classId, List<String> materialIds, {Transaction? txn});
  Future<void> saveFile(MaterialFileModel file, {Transaction? txn});
  Future<void> softDeleteFile(String fileId, {Transaction? txn});
  Future<void> clearAllCache();
}

class LearningMaterialLocalDataSourceImpl
    implements LearningMaterialLocalDataSource {
  @override
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
  Future<void> cacheMaterials(List<LearningMaterialModel> materials, {Transaction? txn}) =>
      ops.cacheMaterials(localDatabase, materials, txn: txn);

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
    Transaction? txn,
  }) =>
      ops.createMaterialLocally(
        localDatabase,
        syncQueue,
        classId,
        title,
        description,
        contentText,
        txn: txn,
      );

  @override
  Future<void> updateMaterialLocally({
    required String materialId,
    required String title,
    required String description,
    required String contentText,
    Transaction? txn,
  }) =>
      ops.updateMaterialLocally(
        localDatabase,
        syncQueue,
        materialId,
        title,
        description,
        contentText,
        txn: txn,
      );

  @override
  Future<void> deleteMaterialLocally(String materialId, {Transaction? txn}) =>
      ops.deleteMaterialLocally(localDatabase, syncQueue, materialId, txn: txn);

  @override
  Future<String> stageMaterialFileForUpload({
    required String materialId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
    required String fileId,
    Transaction? txn,
  }) =>
      ops.stageMaterialFileForUpload(
        localDatabase,
        syncQueue,
        materialId,
        fileName,
        fileType,
        fileSize,
        localPath,
        fileId,
        txn: txn,
      );

  @override
  Future<void> deleteMaterialFileLocally(String fileId, {Transaction? txn}) =>
      ops.deleteMaterialFileLocally(localDatabase, fileId, txn: txn);

  @override
  Future<void> saveMaterial(LearningMaterialModel material, {Transaction? txn}) =>
      ops.saveMaterial(localDatabase, material, txn: txn);

  @override
  Future<void> updateMaterialFields(String materialId, Map<String, dynamic> data, {Transaction? txn}) =>
      ops.updateMaterialFields(localDatabase, materialId, data, txn: txn);

  @override
  Future<void> softDeleteMaterial(String materialId, {Transaction? txn}) =>
      ops.softDeleteMaterial(localDatabase, materialId, txn: txn);

  @override
  Future<void> saveMaterialOrder(String classId, List<String> materialIds, {Transaction? txn}) =>
      ops.saveMaterialOrder(localDatabase, classId, materialIds, txn: txn);

  @override
  Future<void> saveFile(MaterialFileModel file, {Transaction? txn}) =>
      ops.saveFile(localDatabase, file, txn: txn);

  @override
  Future<void> softDeleteFile(String fileId, {Transaction? txn}) =>
      ops.softDeleteFile(localDatabase, fileId, txn: txn);

  @override
  Future<void> clearAllCache() =>
      ops.clearAllCache(localDatabase);
}