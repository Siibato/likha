import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> deleteAssessment(
  DioClient dioClient, {
  required String assessmentId,
}) async {
  try {
    await dioClient.deleteTyped(
      ApiEndpoints.assessmentDetail(assessmentId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
