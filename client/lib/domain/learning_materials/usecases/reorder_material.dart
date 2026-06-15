import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class ReorderMaterial {
  final LearningMaterialRepository _repository;

  ReorderMaterial(this._repository);

  ResultFuture<MutationResult<LearningMaterial>> call({
    required String materialId,
    required int newOrderIndex,
  }) {
    return _repository.reorderMaterial(
      materialId: materialId,
      newOrderIndex: newOrderIndex,
    );
  }
}

class ReorderAllMaterials {
  final LearningMaterialRepository _repository;

  ReorderAllMaterials(this._repository);

  ResultFuture<MutationResult<void>> call({
    required String classId,
    required List<String> materialIds,
  }) {
    return _repository.reorderAllMaterials(
      classId: classId,
      materialIds: materialIds,
    );
  }
}
