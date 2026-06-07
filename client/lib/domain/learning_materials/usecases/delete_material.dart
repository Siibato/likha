import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class DeleteMaterial {
  final LearningMaterialRepository _repository;

  DeleteMaterial(this._repository);

  ResultVoid call(String materialId) {
    return _repository.deleteMaterial(materialId: materialId);
  }
}
