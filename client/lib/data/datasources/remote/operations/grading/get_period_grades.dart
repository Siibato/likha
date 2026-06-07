import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';

Future<List<PeriodGradeModel>> getPeriodGrades(
  DioClient dioClient, {
  required String classId,
  required int gradingPeriodNumber,
}) async {
  try {
    final response = await dioClient.dio.get(
      '${dioClient.dio.options.baseUrl}/classes/$classId/grades',
      queryParameters: {'grading_period_number': gradingPeriodNumber},
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
