import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/models/learning_materials/material_detail_model.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';
import 'package:likha/data/datasources/remote/operations/learning_materials/learning_materials.dart' as ops;

abstract class LearningMaterialRemoteDataSource {
  Future<LearningMaterialModel> createMaterial({
    required String classId,
    required Map<String, dynamic> data,
  });

  Future<List<LearningMaterialModel>> getMaterials({required String classId});

  Future<MaterialDetailModel> getMaterialDetail({required String materialId});

  Future<LearningMaterialModel> updateMaterial({
    required String materialId,
    required Map<String, dynamic> data,
  });

  Future<void> deleteMaterial({required String materialId});

  Future<LearningMaterialModel> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
  });

  Future<void> reorderAllMaterials({
    required String classId,
    required List<String> materialIds,
  });

  Future<MaterialFileModel> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  });

  Future<void> deleteFile({required String fileId});

  Future<List<int>> downloadFile({required String fileId});
}

class LearningMaterialRemoteDataSourceImpl implements LearningMaterialRemoteDataSource {
  final DioClient _dioClient;

  LearningMaterialRemoteDataSourceImpl(this._dioClient);

  @override
  Future<LearningMaterialModel> createMaterial({
    required String classId,
    required Map<String, dynamic> data,
  }) =>
      ops.createMaterial(
        _dioClient,
        classId: classId,
        data: data,
      );

  @override
  Future<List<LearningMaterialModel>> getMaterials({required String classId}) =>
      ops.getMaterials(
        _dioClient,
        classId: classId,
      );

  @override
  Future<MaterialDetailModel> getMaterialDetail({required String materialId}) =>
      ops.getMaterialDetail(
        _dioClient,
        materialId: materialId,
      );

  @override
  Future<LearningMaterialModel> updateMaterial({
    required String materialId,
    required Map<String, dynamic> data,
  }) =>
      ops.updateMaterial(
        _dioClient,
        materialId: materialId,
        data: data,
      );

  @override
  Future<void> deleteMaterial({required String materialId}) =>
      ops.deleteMaterial(
        _dioClient,
        materialId: materialId,
      );

  @override
  Future<LearningMaterialModel> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
  }) =>
      ops.reorderMaterial(
        _dioClient,
        materialId: materialId,
        newOrderIndex: newOrderIndex,
      );

  @override
  Future<void> reorderAllMaterials({
    required String classId,
    required List<String> materialIds,
  }) =>
      ops.reorderAllMaterials(
        _dioClient,
        classId: classId,
        materialIds: materialIds,
      );

  @override
  Future<MaterialFileModel> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) =>
      ops.uploadFile(
        _dioClient,
        materialId: materialId,
        filePath: filePath,
        fileName: fileName,
        onSendProgress: onSendProgress,
      );

  @override
  Future<void> deleteFile({required String fileId}) =>
      ops.deleteFile(
        _dioClient,
        fileId: fileId,
      );

  @override
  Future<List<int>> downloadFile({required String fileId}) =>
      ops.downloadFile(
        _dioClient,
        fileId: fileId,
      );
}
