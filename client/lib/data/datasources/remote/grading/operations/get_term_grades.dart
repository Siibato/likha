import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';

Future<List<PeriodGradeModel>> getTermGrades(
  DioClient dioClient, {
  required String classId,
  required int termNumber,
}) async {
  try {
    final response = await dioClient.dio.get(
      ApiEndpoints.classGrades(classId).path,
      queryParameters: {'term_number': termNumber},
    );
    final data = response.data['data'] ?? response.data;
    final grades = data['grades'] as List<dynamic>? ?? [];
    return grades
        .map(
            (e) => PeriodGradeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
