import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';

Future<AssignmentModel> updateAssignment(
  DioClient dioClient, {
  required String assignmentId,
  required Map<String, dynamic> data,
}) async {
  try {
    return await dioClient.putTyped(
      ApiEndpoints.assignmentDetail(assignmentId),
      data: data,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
