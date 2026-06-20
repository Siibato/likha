import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<List<Map<String, dynamic>>> getGradeSummary(
  DioClient dioClient, {
  required String classId,
  required int termNumber,
}) async {
  try {
    final response = await dioClient.dio.get(
      ApiEndpoints.classGradesSummary(classId).path,
      queryParameters: {'term_number': termNumber},
    );
    final data = response.data['data'] ?? response.data;
    final summary = data['students'] as List<dynamic>? ?? [];
    return summary.cast<Map<String, dynamic>>();
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
