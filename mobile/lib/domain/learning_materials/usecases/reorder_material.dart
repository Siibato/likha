import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class ReorderMaterial {
  final LearningMaterialRepository _repository;

  ReorderMaterial(this._repository);

  ResultFuture<LearningMaterial> call({
    required String materialId,
    required int newOrderIndex,
  }) {
    return _repository.reorderMaterial(
      materialId: materialId,
      newOrderIndex: newOrderIndex,
    );
  }
}
