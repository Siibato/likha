import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/models/learning_materials/material_detail_model.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';

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

  Future<MaterialFileModel> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
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
  }) async {
    return await _dioClient.postTyped(
      ApiEndpoints.classMaterials(classId),
      data: data,
    );
  }

  @override
  Future<List<LearningMaterialModel>> getMaterials({required String classId}) async {
    return await _dioClient.getTyped(
      ApiEndpoints.classMaterialsList(classId),
    );
  }

  @override
  Future<MaterialDetailModel> getMaterialDetail({required String materialId}) async {
    return await _dioClient.getTyped(
      ApiEndpoints.materialDetail(materialId),
    );
  }

  @override
  Future<LearningMaterialModel> updateMaterial({
    required String materialId,
    required Map<String, dynamic> data,
  }) async {
    return await _dioClient.putTyped(
      ApiEndpoints.materialUpdate(materialId),
      data: data,
    );
  }

  @override
  Future<void> deleteMaterial({required String materialId}) async {
    await _dioClient.deleteTyped(
      ApiEndpoints.materialDetail(materialId),
    );
  }

  @override
  Future<LearningMaterialModel> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
  }) async {
    return await _dioClient.postTyped(
      ApiEndpoints.materialReorder(materialId),
      data: {'new_order_index': newOrderIndex},
    );
  }

  @override
  Future<MaterialFileModel> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: MediaType('application', 'octet-stream'),
      ),
    });

    final response = await _dioClient.dio.post(
      ApiEndpoints.materialUploadFile(materialId).path,
      data: formData,
    );
    return MaterialFileModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteFile({required String fileId}) async {
    await _dioClient.deleteTyped(
      ApiEndpoints.materialFileDelete(fileId),
    );
  }

  @override
  Future<List<int>> downloadFile({required String fileId}) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.materialFileDownload(fileId).path,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }
}
