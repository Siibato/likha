import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';

abstract class LearningMaterialRepository {
  // Material CRUD
  ResultFuture<LearningMaterial> createMaterial({
    required String classId,
    required String title,
    String? description,
    String? contentText,
  });

  ResultFuture<List<LearningMaterial>> getMaterials({required String classId});

  ResultFuture<MaterialDetail> getMaterialDetail({required String materialId});

  ResultFuture<LearningMaterial> updateMaterial({
    required String materialId,
    String? title,
    String? description,
    String? contentText,
  });

  ResultVoid deleteMaterial({required String materialId});

  ResultFuture<LearningMaterial> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
  });

  // File management
  ResultFuture<MaterialFile> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
  });

  ResultVoid deleteFile({required String fileId});

  ResultFuture<List<int>> downloadFile({required String fileId});
}
