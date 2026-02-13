import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class UploadFile {
  final LearningMaterialRepository _repository;

  UploadFile(this._repository);

  ResultFuture<MaterialFile> call({
    required String materialId,
    required String filePath,
    required String fileName,
  }) {
    return _repository.uploadFile(
      materialId: materialId,
      filePath: filePath,
      fileName: fileName,
    );
  }
}
