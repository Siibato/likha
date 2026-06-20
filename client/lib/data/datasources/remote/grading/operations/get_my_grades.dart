import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/term_grade_model.dart';

Future<List<TermGradeModel>> getMyGrades(
  DioClient dioClient, {
  required String classId,
}) async {
  try {
    final response = await dioClient.dio.get(
      ApiEndpoints.myGrades(classId).path,
    );
    final data = response.data['data'] ?? response.data;
    final grades = data['grades'] as List<dynamic>? ?? [];
    return grades
        .map(
            (e) => TermGradeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
