import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class CheckFileCached {
  final LearningMaterialRepository _repository;

  CheckFileCached(this._repository);

  Future<bool> call(String fileId) {
    return _repository.checkFileCached(fileId: fileId);
  }
}
