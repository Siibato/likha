import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

abstract class DocumentExportRemoteDataSource {
  Future<List<int>> exportClassGradesPdf({
    required String classId,
    required int period,
  });

  Future<List<int>> exportClassGradesExcel({
    required String classId,
    required int period,
  });

  Future<List<int>> exportSf9Pdf({
    required String classId,
    required String studentId,
  });

  Future<List<int>> exportSf10Pdf({
    required String classId,
    required String studentId,
  });

  Future<List<int>> exportSf10Excel({
    required String classId,
    required String studentId,
  });
}

class DocumentExportRemoteDataSourceImpl implements DocumentExportRemoteDataSource {
  final DioClient _dioClient;

  DocumentExportRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<int>> exportClassGradesPdf({
    required String classId,
    required int period,
  }) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.exportGradesPdf(classId, period: period),
      options: Options(responseType: ResponseType.bytes),
    );
    return (response.data as List<dynamic>).cast<int>();
  }

  @override
  Future<List<int>> exportClassGradesExcel({
    required String classId,
    required int period,
  }) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.exportGradesExcel(classId, period: period),
      options: Options(responseType: ResponseType.bytes),
    );
    return (response.data as List<dynamic>).cast<int>();
  }

  @override
  Future<List<int>> exportSf9Pdf({
    required String classId,
    required String studentId,
  }) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.exportSf9Pdf(classId, studentId),
      options: Options(responseType: ResponseType.bytes),
    );
    return (response.data as List<dynamic>).cast<int>();
  }

  @override
  Future<List<int>> exportSf10Pdf({
    required String classId,
    required String studentId,
  }) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.exportSf10Pdf(classId, studentId),
      options: Options(responseType: ResponseType.bytes),
    );
    return (response.data as List<dynamic>).cast<int>();
  }

  @override
  Future<List<int>> exportSf10Excel({
    required String classId,
    required String studentId,
  }) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.exportSf10Excel(classId, studentId),
      options: Options(responseType: ResponseType.bytes),
    );
    return (response.data as List<dynamic>).cast<int>();
  }
}
