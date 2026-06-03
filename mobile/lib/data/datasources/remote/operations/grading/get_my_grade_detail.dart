import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<Map<String, dynamic>> getMyGradeDetail(
  DioClient dioClient, {
  required String classId,
  required int gradingPeriodNumber,
}) async {
  try {
    final response = await dioClient.dio.get(
      dioClient.dio.options.baseUrl + '/classes/$classId/my-grades/$gradingPeriodNumber',
    );
    return (response.data['data'] ?? response.data) as Map<String, dynamic>;
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
