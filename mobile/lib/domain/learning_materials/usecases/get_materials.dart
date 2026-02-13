import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class GetMaterials {
  final LearningMaterialRepository _repository;

  GetMaterials(this._repository);

  ResultFuture<List<LearningMaterial>> call(String classId) {
    return _repository.getMaterials(classId: classId);
  }
}
