import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<void> setupGrading(
  DioClient dioClient, {
  required String classId,
  required Map<String, dynamic> data,
}) async {
  try {
    await dioClient.dio.post(
      dioClient.dio.options.baseUrl + '/classes/$classId/grading-config/setup',
      data: data,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
