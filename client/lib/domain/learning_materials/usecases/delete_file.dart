import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class DeleteFile {
  final LearningMaterialRepository _repository;

  DeleteFile(this._repository);

  ResultVoid call(String fileId) {
    return _repository.deleteFile(fileId: fileId);
  }
}
