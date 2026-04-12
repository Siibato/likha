import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/quarterly_grade_model.dart';
import 'package:likha/data/models/grading/general_average_model.dart';
import 'package:likha/data/models/grading/sf9_model.dart';

abstract class GradingRemoteDataSource {
  // Config
  Future<List<GradeConfigModel>> getGradingConfig({required String classId});
  Future<void> setupGrading({
    required String classId,
    required Map<String, dynamic> data,
  });
  Future<void> updateGradingConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
  });

  // Grade Items
  Future<List<GradeItemModel>> getGradeItems({
    required String classId,
    required int quarter,
    String? component,
  });
  Future<GradeItemModel> createGradeItem({
    required String classId,
    required Map<String, dynamic> data,
  });
  Future<void> updateGradeItem({
    required String id,
    required Map<String, dynamic> data,
  });
  Future<void> deleteGradeItem({required String id});

  // Scores
  Future<List<GradeScoreModel>> getScoresByItem({required String gradeItemId});
  Future<void> saveScores({
    required String gradeItemId,
    required List<Map<String, dynamic>> scores,
  });
  Future<void> setScoreOverride({
    required String scoreId,
    required double overrideScore,
  });
  Future<void> clearScoreOverride({required String scoreId});

  // Computed Grades
  Future<List<QuarterlyGradeModel>> getQuarterlyGrades({
    required String classId,
    required int quarter,
  });
  Future<void> computeGrades({
    required String classId,
    required int quarter,
  });
  Future<List<Map<String, dynamic>>> getGradeSummary({
    required String classId,
    required int quarter,
  });
  Future<List<Map<String, dynamic>>> getFinalGrades({required String classId});

  // Student
  Future<List<QuarterlyGradeModel>> getMyGrades({required String classId});
  Future<Map<String, dynamic>> getMyGradeDetail({
    required String classId,
    required int quarter,
  });

  // Presets
  Future<Map<String, dynamic>> getDepEdPresets();

  // General Average
  Future<GeneralAverageResponseModel> getGeneralAverages({
    required String classId,
  });

  // SF9/SF10
  Future<Sf9ResponseModel> getSf9({
    required String classId,
    required String studentId,
  });
  Future<Sf9ResponseModel> getSf10({
    required String classId,
    required String studentId,
  });
}

class GradingRemoteDataSourceImpl implements GradingRemoteDataSource {
  final DioClient _dioClient;

  GradingRemoteDataSourceImpl(this._dioClient);

  // ===== Config =====

  @override
  Future<List<GradeConfigModel>> getGradingConfig({
    required String classId,
  }) async {
    try {
      ProviderLogger.instance.debug('getGradingConfig called for classId: $classId');
      final response = await _dioClient.dio.get(
        ApiEndpoints.gradingConfig(classId).path,
      );
      ProviderLogger.instance.debug('API response: ${response.data}');
      final raw = response.data['data'] ?? response.data;
      ProviderLogger.instance.debug('raw data: $raw');
      ProviderLogger.instance.debug('raw is List? ${raw is List}');
      ProviderLogger.instance.debug('raw runtime type: ${raw.runtimeType}');
      final configs = raw is List ? raw : (raw['configs'] as List<dynamic>? ?? []);
      ProviderLogger.instance.debug('final configs count: ${configs.length}');
      return configs
          .map((e) => GradeConfigModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> setupGrading({
    required String classId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _dioClient.dio.post(
        ApiEndpoints.gradingConfigSetup(classId).path,
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> updateGradingConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
  }) async {
    try {
      await _dioClient.dio.put(
        ApiEndpoints.gradingConfig(classId).path,
        data: {'configs': configs},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  // ===== Grade Items =====

  @override
  Future<List<GradeItemModel>> getGradeItems({
    required String classId,
    required int quarter,
    String? component,
  }) async {
    try {
      final queryParams = <String, dynamic>{'quarter': quarter};
      if (component != null) queryParams['component'] = component;

      final response = await _dioClient.dio.get(
        ApiEndpoints.gradeItems(classId).path,
        queryParameters: queryParams,
      );
      final data = response.data['data'] ?? response.data;
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => GradeItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<GradeItemModel> createGradeItem({
    required String classId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.gradeItems(classId).path,
        data: data,
      );
      final responseData = response.data['data'] ?? response.data;
      return GradeItemModel.fromJson(responseData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> updateGradeItem({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _dioClient.dio.put(
        ApiEndpoints.gradeItemDetail(id).path,
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteGradeItem({required String id}) async {
    try {
      await _dioClient.dio.delete(
        ApiEndpoints.gradeItemDetail(id).path,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  // ===== Scores =====

  @override
  Future<List<GradeScoreModel>> getScoresByItem({
    required String gradeItemId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.gradeItemScores(gradeItemId).path,
      );
      final data = response.data['data'] ?? response.data;
      final scores = data['scores'] as List<dynamic>? ?? [];
      return scores
          .map((e) => GradeScoreModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> saveScores({
    required String gradeItemId,
    required List<Map<String, dynamic>> scores,
  }) async {
    try {
      await _dioClient.dio.put(
        ApiEndpoints.gradeItemScores(gradeItemId).path,
        data: {'scores': scores},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> setScoreOverride({
    required String scoreId,
    required double overrideScore,
  }) async {
    try {
      await _dioClient.dio.put(
        ApiEndpoints.gradeScoreOverride(scoreId).path,
        data: {'override_score': overrideScore},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> clearScoreOverride({required String scoreId}) async {
    try {
      await _dioClient.dio.delete(
        ApiEndpoints.gradeScoreOverride(scoreId).path,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  // ===== Computed Grades =====

  @override
  Future<List<QuarterlyGradeModel>> getQuarterlyGrades({
    required String classId,
    required int quarter,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.classGrades(classId).path,
        queryParameters: {'quarter': quarter},
      );
      final data = response.data['data'] ?? response.data;
      final grades = data['grades'] as List<dynamic>? ?? [];
      return grades
          .map(
              (e) => QuarterlyGradeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> computeGrades({
    required String classId,
    required int quarter,
  }) async {
    try {
      await _dioClient.dio.post(
        ApiEndpoints.classGradesCompute(classId).path,
        queryParameters: {'quarter': quarter},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getGradeSummary({
    required String classId,
    required int quarter,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.classGradesSummary(classId).path,
        queryParameters: {'quarter': quarter},
      );
      final data = response.data['data'] ?? response.data;
      final summary = data['summary'] as List<dynamic>? ?? [];
      return summary.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFinalGrades({
    required String classId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.classGradesFinal(classId).path,
      );
      final data = response.data['data'] ?? response.data;
      final grades = data['grades'] as List<dynamic>? ?? [];
      return grades.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  // ===== Student =====

  @override
  Future<List<QuarterlyGradeModel>> getMyGrades({
    required String classId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.myGrades(classId).path,
      );
      final data = response.data['data'] ?? response.data;
      final grades = data['grades'] as List<dynamic>? ?? [];
      return grades
          .map(
              (e) => QuarterlyGradeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getMyGradeDetail({
    required String classId,
    required int quarter,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.myGradeDetail(classId, quarter).path,
      );
      return (response.data['data'] ?? response.data) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  // ===== Presets =====

  @override
  Future<Map<String, dynamic>> getDepEdPresets() async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.depEdPresets.path,
      );
      return (response.data['data'] ?? response.data) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  // ===== General Average =====

  @override
  Future<GeneralAverageResponseModel> getGeneralAverages({
    required String classId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.generalAverage(classId).path,
      );
      final data = response.data['data'] ?? response.data;
      return GeneralAverageResponseModel.fromJson(
        data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  // ===== SF9/SF10 =====

  @override
  Future<Sf9ResponseModel> getSf9({
    required String classId,
    required String studentId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.sf9(classId, studentId).path,
      );
      final data = response.data['data'] ?? response.data;
      return Sf9ResponseModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<Sf9ResponseModel> getSf10({
    required String classId,
    required String studentId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.sf10(classId, studentId).path,
      );
      final data = response.data['data'] ?? response.data;
      return Sf9ResponseModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }
}
