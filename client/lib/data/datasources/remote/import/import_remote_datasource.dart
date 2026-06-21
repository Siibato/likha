import 'package:dio/dio.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/network/api_types.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/data/models/import/import_preview_model.dart';

abstract class ImportRemoteDataSource {
  Future<PreviewResponseModel> previewStudentImport(String filePath);
  Future<ImportResultModel> importStudents(List<Map<String, dynamic>> rows);

  Future<PreviewResponseModel> previewHistoryImport(String filePath, String type);
  Future<ImportResultModel> importHistory(List<Map<String, dynamic>> rows, String type);
}

class ImportRemoteDataSourceImpl implements ImportRemoteDataSource {
  final DioClient _dioClient;

  ImportRemoteDataSourceImpl(this._dioClient);

  @override
  Future<PreviewResponseModel> previewStudentImport(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'students.csv'),
    });

    final response = await _dioClient.dio.post(
      ApiEndpoints.studentImportPreview().path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => PreviewResponseModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.unwrap();
  }

  @override
  Future<ImportResultModel> importStudents(List<Map<String, dynamic>> rows) async {
    final endpoint = ApiEndpoints.studentImport();
    final response = await _dioClient.dio.post(
      endpoint.path,
      data: {'rows': rows},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => ImportResultModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.unwrap();
  }

  @override
  Future<PreviewResponseModel> previewHistoryImport(String filePath, String type) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'history.csv'),
    });

    final endpoint = ApiEndpoints.historyImportPreview(type);
    final response = await _dioClient.dio.post(
      endpoint.path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => PreviewResponseModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.unwrap();
  }

  @override
  Future<ImportResultModel> importHistory(List<Map<String, dynamic>> rows, String type) async {
    final endpoint = ApiEndpoints.historyImport(type);
    final response = await _dioClient.dio.post(
      endpoint.path,
      data: {'rows': rows},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => ImportResultModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.unwrap();
  }
}
