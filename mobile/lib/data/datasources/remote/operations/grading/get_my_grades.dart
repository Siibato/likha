import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';

Future<List<PeriodGradeModel>> getMyGrades(
  DioClient dioClient, {
  required String classId,
}) async {
  try {
    final response = await dioClient.dio.get(
      dioClient.dio.options.baseUrl + '/classes/$classId/my-grades',
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
