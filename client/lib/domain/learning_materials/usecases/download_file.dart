import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class DownloadFile {
  final LearningMaterialRepository _repository;

  DownloadFile(this._repository);

  ResultFuture<List<int>> call(String fileId) {
    return _repository.downloadFile(fileId: fileId);
  }
}
