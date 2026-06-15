import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';

abstract class LearningMaterialRepository {
  // Material CRUD
  ResultFuture<MutationResult<LearningMaterial>> createMaterial({
    required String classId,
    required String title,
    String? description,
    String? contentText,
  });

  ResultFuture<List<LearningMaterial>> getMaterials({required String classId});

  ResultFuture<MaterialDetail> getMaterialDetail({required String materialId, bool skipBackgroundRefresh = false});

  ResultFuture<MutationResult<LearningMaterial>> updateMaterial({
    required String materialId,
    String? title,
    String? description,
    String? contentText,
  });

  ResultFuture<MutationResult<void>> deleteMaterial({required String materialId});

  ResultFuture<MutationResult<LearningMaterial>> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
  });

  ResultFuture<MutationResult<void>> reorderAllMaterials({
    required String classId,
    required List<String> materialIds,
  });

  // File management
  ResultFuture<MutationResult<MaterialFile>> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  });

  ResultFuture<MutationResult<void>> deleteFile({required String fileId});

  ResultFuture<List<int>> downloadFile({required String fileId});
}
