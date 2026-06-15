import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';

Future<AssignmentModel> publishAssignment(
  DioClient dioClient, {
  required String assignmentId,
  String? idempotencyKey,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.assignmentPublish(assignmentId),
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
