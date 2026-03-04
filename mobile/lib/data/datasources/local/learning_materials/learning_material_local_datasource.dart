import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';

abstract class LearningMaterialLocalDataSource {
  Future<List<LearningMaterialModel>> getCachedMaterials(String classId);
  Future<LearningMaterialModel> getCachedMaterialDetail(String materialId);
  Future<List<MaterialFileModel>> getCachedMaterialFiles(String materialId);
  Future<void> cacheMaterials(List<LearningMaterialModel> materials);
  Future<void> cacheMaterialDetail(LearningMaterialModel material);
  Future<void> cacheFile(String fileId, String fileName, List<int> bytes);
  Future<List<int>> getCachedFile(String fileId);
  Future<bool> isFileCached(String fileId);
  Future<LearningMaterialModel> createMaterialLocally({
    required String classId,
    required String title,
    required String description,
    required String contentText,
  });
  Future<void> updateMaterialLocally({
    required String materialId,
    required String title,
    required String description,
    required String contentText,
  });
  Future<void> stageMaterialFileForUpload({
    required String materialId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  });
  Future<void> clearAllCache();
}