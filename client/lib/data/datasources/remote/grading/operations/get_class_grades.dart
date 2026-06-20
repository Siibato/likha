import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';

Future<Map<String, dynamic>> getClassGrades(
  DioClient dioClient, {
  required String classId,
  required int gradingPeriodNumber,
}) async {
  try {
    final response = await dioClient.dio.get(
      ApiEndpoints.gradeData(classId).path,
      queryParameters: {'grading_period_number': gradingPeriodNumber},
    );
    final data = response.data['data'] ?? response.data;
    return data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}

List<GradeItemModel> parseGradeItems(Map<String, dynamic> data) {
  final items = data['grade_items'] as List<dynamic>? ?? [];
  return items.map((e) => GradeItemModel.fromJson(e as Map<String, dynamic>)).toList();
}

Map<String, List<GradeScoreModel>> parseScoresByItem(Map<String, dynamic> data) {
  final raw = data['scores_by_item'] as Map<String, dynamic>? ?? {};
  return raw.map((itemId, scores) {
    final list = scores as List<dynamic>;
    return MapEntry(
      itemId,
      list.map((e) => GradeScoreModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  });
}

GradeConfigModel? parseConfig(Map<String, dynamic> data) {
  final raw = data['config'];
  if (raw == null) return null;
  return GradeConfigModel.fromJson(raw as Map<String, dynamic>);
}

List<Map<String, dynamic>> parseGradeSummary(Map<String, dynamic> data) {
  final summary = data['grade_summary'] as Map<String, dynamic>? ?? {};
  final students = summary['students'] as List<dynamic>? ?? [];
  return students.cast<Map<String, dynamic>>();
}
