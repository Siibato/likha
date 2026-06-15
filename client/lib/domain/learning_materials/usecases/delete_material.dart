import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class DeleteMaterial {
  final LearningMaterialRepository _repository;

  DeleteMaterial(this._repository);

  ResultFuture<MutationResult<void>> call(String materialId) {
    return _repository.deleteMaterial(materialId: materialId);
  }
}
