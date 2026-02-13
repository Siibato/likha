import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:likha/core/constants/api_constants.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/domain/learning_materials/data/models/learning_material_model.dart';
import 'package:likha/domain/learning_materials/data/models/material_detail_model.dart';
import 'package:likha/domain/learning_materials/data/models/material_file_model.dart';

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
    final response = await _dioClient.dio.post(
      ApiConstants.classMaterials(classId),
      data: data,
    );
    return LearningMaterialModel.fromJson(response.data['data']);
  }

  @override
  Future<List<LearningMaterialModel>> getMaterials({required String classId}) async {
    final response = await _dioClient.dio.get(
      ApiConstants.classMaterials(classId),
    );
    final materialsJson = response.data['data']['materials'] as List;
    return materialsJson.map((json) => LearningMaterialModel.fromJson(json)).toList();
  }

  @override
  Future<MaterialDetailModel> getMaterialDetail({required String materialId}) async {
    final response = await _dioClient.dio.get(
      ApiConstants.materialDetail(materialId),
    );
    return MaterialDetailModel.fromJson(response.data['data']);
  }

  @override
  Future<LearningMaterialModel> updateMaterial({
    required String materialId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.dio.put(
      ApiConstants.materialDetail(materialId),
      data: data,
    );
    return LearningMaterialModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteMaterial({required String materialId}) async {
    await _dioClient.dio.delete(
      ApiConstants.materialDetail(materialId),
    );
  }

  @override
  Future<LearningMaterialModel> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.materialReorder(materialId),
      data: {'new_order_index': newOrderIndex},
    );
    return LearningMaterialModel.fromJson(response.data['data']);
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
      ApiConstants.materialUploadFile(materialId),
      data: formData,
    );
    return MaterialFileModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteFile({required String fileId}) async {
    await _dioClient.dio.delete(
      ApiConstants.materialFileDelete(fileId),
    );
  }

  @override
  Future<List<int>> downloadFile({required String fileId}) async {
    final response = await _dioClient.dio.get(
      ApiConstants.materialFileDownload(fileId),
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }
}
