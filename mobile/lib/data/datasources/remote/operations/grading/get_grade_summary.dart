import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<List<Map<String, dynamic>>> getGradeSummary(
  DioClient dioClient, {
  required String classId,
  required int gradingPeriodNumber,
}) async {
  try {
    final response = await dioClient.dio.get(
      '${dioClient.dio.options.baseUrl}/classes/$classId/grades/summary',
      queryParameters: {'grading_period_number': gradingPeriodNumber},
    );
    final data = response.data['data'] ?? response.data;
    final summary = data['summary'] as List<dynamic>? ?? [];
    return summary.cast<Map<String, dynamic>>();
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
