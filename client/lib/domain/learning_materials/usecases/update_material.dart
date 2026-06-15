import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class UpdateMaterial {
  final LearningMaterialRepository _repository;

  UpdateMaterial(this._repository);

  ResultFuture<LearningMaterial> call({
    required String materialId,
    String? title,
    String? description,
    String? contentText,
  }) {
    return _repository.updateMaterial(
      materialId: materialId,
      title: title,
      description: description,
      contentText: contentText,
    );
  }
}
