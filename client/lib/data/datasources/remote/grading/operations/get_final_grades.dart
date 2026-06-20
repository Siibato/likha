import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<List<Map<String, dynamic>>> getFinalGrades(
  DioClient dioClient, {
  required String classId,
}) async {
  try {
    final response = await dioClient.dio.get(
      ApiEndpoints.classGradesFinal(classId).path,
    );
    final data = response.data['data'] ?? response.data;
    final grades = data['grades'] as List<dynamic>? ?? [];
    return grades.cast<Map<String, dynamic>>();
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
