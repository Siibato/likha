import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<void> updateGradingConfig(
  DioClient dioClient, {
  required String classId,
  required List<Map<String, dynamic>> configs,
}) async {
  try {
    await dioClient.dio.put(
      dioClient.dio.options.baseUrl + '/classes/$classId/grading-config',
      data: {'configs': configs},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
