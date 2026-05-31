import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> deleteAssignment(
  DioClient dioClient, {
  required String assignmentId,
}) async {
  try {
    await dioClient.deleteTyped(
      ApiEndpoints.assignmentDetail(assignmentId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
