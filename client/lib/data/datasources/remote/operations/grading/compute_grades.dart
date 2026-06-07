import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<void> computeGrades(
  DioClient dioClient, {
  required String classId,
  required int gradingPeriodNumber,
}) async {
  try {
    await dioClient.dio.post(
      '${dioClient.dio.options.baseUrl}/classes/$classId/grades/compute',
      queryParameters: {'grading_period_number': gradingPeriodNumber},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
