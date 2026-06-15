import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class GetMaterialDetail {
  final LearningMaterialRepository _repository;

  GetMaterialDetail(this._repository);

  ResultFuture<MaterialDetail> call(String materialId) {
    return _repository.getMaterialDetail(materialId: materialId);
  }
}
