import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class CreateMaterial {
  final LearningMaterialRepository _repository;

  CreateMaterial(this._repository);

  ResultFuture<LearningMaterial> call({
    required String classId,
    required String title,
    String? description,
    String? contentText,
  }) {
    return _repository.createMaterial(
      classId: classId,
      title: title,
      description: description,
      contentText: contentText,
    );
  }
}
