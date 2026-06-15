import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/models/learning_materials/material_detail_model.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';
import 'package:likha/data/datasources/remote/learning_materials/operations/learning_materials.dart' as ops;

abstract class LearningMaterialRemoteDataSource {
  Future<LearningMaterialModel> createMaterial({
    required String classId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  });

  Future<List<LearningMaterialModel>> getMaterials({required String classId});

  Future<MaterialDetailModel> getMaterialDetail({required String materialId});

  Future<LearningMaterialModel> updateMaterial({
    required String materialId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  });

  Future<void> deleteMaterial({required String materialId, String? idempotencyKey});

  Future<LearningMaterialModel> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
    String? idempotencyKey,
  });

  Future<void> reorderAllMaterials({
    required String classId,
    required List<String> materialIds,
    String? idempotencyKey,
  });

  Future<MaterialFileModel> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
    String? idempotencyKey,
  });

  Future<void> deleteFile({required String fileId, String? idempotencyKey});

  Future<List<int>> downloadFile({required String fileId});
}

class LearningMaterialRemoteDataSourceImpl implements LearningMaterialRemoteDataSource {
  final DioClient _dioClient;

  LearningMaterialRemoteDataSourceImpl(this._dioClient);

  @override
  Future<LearningMaterialModel> createMaterial({
    required String classId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      ops.createMaterial(
        _dioClient,
        classId: classId,
        data: data,
        idempotencyKey: idempotencyKey,
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
    String? idempotencyKey,
  }) =>
      ops.updateMaterial(
        _dioClient,
        materialId: materialId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> deleteMaterial({required String materialId, String? idempotencyKey}) =>
      ops.deleteMaterial(
        _dioClient,
        materialId: materialId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<LearningMaterialModel> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
    String? idempotencyKey,
  }) =>
      ops.reorderMaterial(
        _dioClient,
        materialId: materialId,
        newOrderIndex: newOrderIndex,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> reorderAllMaterials({
    required String classId,
    required List<String> materialIds,
    String? idempotencyKey,
  }) =>
      ops.reorderAllMaterials(
        _dioClient,
        classId: classId,
        materialIds: materialIds,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<MaterialFileModel> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
    String? idempotencyKey,
  }) =>
      ops.uploadFile(
        _dioClient,
        materialId: materialId,
        filePath: filePath,
        fileName: fileName,
        onSendProgress: onSendProgress,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> deleteFile({required String fileId, String? idempotencyKey}) =>
      ops.deleteFile(
        _dioClient,
        fileId: fileId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<List<int>> downloadFile({required String fileId}) =>
      ops.downloadFile(
        _dioClient,
        fileId: fileId,
      );
}
