import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoint.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/data/models/tos/melcs_model.dart';

abstract class TosRemoteDataSource {
  Future<List<TosModel>> getTosByClass({required String classId});
  Future<(TosModel, List<CompetencyModel>)> getTosDetail({required String tosId});
  Future<TosModel> createTos({required String classId, required Map<String, dynamic> data});
  Future<TosModel> updateTos({required String tosId, required Map<String, dynamic> data});
  Future<void> deleteTos({required String tosId});
  Future<CompetencyModel> addCompetency({required String tosId, required Map<String, dynamic> data});
  Future<CompetencyModel> updateCompetency({required String competencyId, required Map<String, dynamic> data});
  Future<void> deleteCompetency({required String competencyId});
  Future<List<CompetencyModel>> bulkAddCompetencies({required String tosId, required List<Map<String, dynamic>> competencies});
  Future<List<MelcEntryModel>> searchMelcs({String? subject, String? gradeLevel, int? quarter, String? query});
}

class TosRemoteDataSourceImpl implements TosRemoteDataSource {
  final DioClient _dioClient;

  TosRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<TosModel>> getTosByClass({required String classId}) async {
    try {
      return await _dioClient.getTyped(
        ApiEndpoints.tosList(classId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<(TosModel, List<CompetencyModel>)> getTosDetail({required String tosId}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.tosDetail(tosId).path,
      );
      final data = response.data['data'] ?? response.data;
      final tos = TosModel.fromJson(data as Map<String, dynamic>);
      final competencies = (data['competencies'] as List<dynamic>? ?? [])
          .map((e) => CompetencyModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (tos, competencies);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<TosModel> createTos({
    required String classId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.tosList(classId).path,
        data: data,
      );
      final responseData = response.data['data'] ?? response.data;
      return TosModel.fromJson(responseData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<TosModel> updateTos({
    required String tosId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        ApiEndpoints.tosDetail(tosId).path,
        data: data,
      );
      final responseData = response.data['data'] ?? response.data;
      return TosModel.fromJson(responseData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteTos({required String tosId}) async {
    try {
      await _dioClient.deleteTyped(
        ApiEndpoint<void>(
          ApiEndpoints.tosDetail(tosId).path,
          (_) {},
        ),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<CompetencyModel> addCompetency({
    required String tosId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.tosCompetencies(tosId).path,
        data: data,
      );
      final responseData = response.data['data'] ?? response.data;
      return CompetencyModel.fromJson(responseData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<CompetencyModel> updateCompetency({
    required String competencyId,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _dioClient.putTyped(
        ApiEndpoints.tosCompetencyDetail(competencyId),
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteCompetency({required String competencyId}) async {
    try {
      await _dioClient.deleteTyped(
        ApiEndpoint<void>(
          ApiEndpoints.tosCompetencyDetail(competencyId).path,
          (_) {},
        ),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<CompetencyModel>> bulkAddCompetencies({
    required String tosId,
    required List<Map<String, dynamic>> competencies,
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.tosBulkCompetencies(tosId),
        data: {'competencies': competencies},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? quarter,
    String? query,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (subject != null) queryParams['subject'] = subject;
      if (gradeLevel != null) queryParams['grade_level'] = gradeLevel;
      if (quarter != null) queryParams['quarter'] = quarter;
      if (query != null) queryParams['q'] = query;

      final response = await _dioClient.dio.get(
        ApiEndpoints.melcsSearch().path,
        queryParameters: queryParams,
      );
      final data = response.data['data'] ?? response.data;
      final items = data['melcs'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
      return items
          .map((e) => MelcEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }
}
