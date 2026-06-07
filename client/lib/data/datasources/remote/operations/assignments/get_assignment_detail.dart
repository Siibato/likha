import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';

Future<AssignmentModel> getAssignmentDetail(
  DioClient dioClient, {
  required String assignmentId,
}) async {
  try {
    return await dioClient.getTyped(
      ApiEndpoints.assignmentDetail(assignmentId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
