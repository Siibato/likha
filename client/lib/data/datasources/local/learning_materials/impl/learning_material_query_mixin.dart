import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';
import '../learning_material_local_datasource_base.dart';
import 'operations/query/get_cached_materials.dart';
import 'operations/query/get_cached_material_detail.dart';
import 'operations/query/get_cached_material_files.dart';

mixin LearningMaterialQueryMixin on LearningMaterialLocalDataSourceBase {
  @override
  Future<List<LearningMaterialModel>> getCachedMaterials(String classId) async {
    return getCachedMaterialsOp(localDatabase, classId);
  }

  @override
  Future<LearningMaterialModel> getCachedMaterialDetail(String materialId) async {
    return getCachedMaterialDetailOp(localDatabase, materialId);
  }

  @override
  Future<List<MaterialFileModel>> getCachedMaterialFiles(String materialId) async {
    return getCachedMaterialFilesOp(localDatabase, materialId);
  }
}