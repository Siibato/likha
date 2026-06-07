import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';

Future<AssignmentModel> createAssignment(
  DioClient dioClient, {
  required String classId,
  required Map<String, dynamic> data,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.classAssignments(classId),
      data: data,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
