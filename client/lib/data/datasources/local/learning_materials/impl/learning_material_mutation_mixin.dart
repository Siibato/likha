import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import '../learning_material_local_datasource_base.dart';
import 'operations/mutation/create_material_locally.dart';
import 'operations/mutation/update_material_locally.dart';
import 'operations/mutation/delete_material_locally.dart';
import 'operations/mutation/stage_material_file_for_upload.dart';
import 'operations/mutation/delete_material_file_locally.dart';

mixin LearningMaterialMutationMixin on LearningMaterialLocalDataSourceBase {
  @override
  Future<LearningMaterialModel> createMaterialLocally({
    required String classId,
    required String title,
    required String description,
    required String contentText,
  }) async {
    return createMaterialLocallyOp(localDatabase, syncQueue, classId, title, description, contentText);
  }

  @override
  Future<void> updateMaterialLocally({
    required String materialId,
    required String title,
    required String description,
    required String contentText,
  }) async {
    return updateMaterialLocallyOp(localDatabase, syncQueue, materialId, title, description, contentText);
  }

  @override
  Future<void> deleteMaterialLocally(String materialId) async {
    return deleteMaterialLocallyOp(localDatabase, syncQueue, materialId);
  }

  @override
  Future<void> stageMaterialFileForUpload({
    required String materialId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  }) async {
    return stageMaterialFileForUploadOp(localDatabase, syncQueue, materialId, fileName, fileType, fileSize, localPath);
  }

  @override
  Future<void> deleteMaterialFileLocally(String fileId) async {
    return deleteMaterialFileLocallyOp(localDatabase, fileId);
  }
}