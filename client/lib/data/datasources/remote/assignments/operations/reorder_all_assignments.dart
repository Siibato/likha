import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> reorderAllAssignments(
  DioClient dioClient, {
  required String classId,
  required List<String> assignmentIds,
  String? idempotencyKey,
}) async {
  try {
    await dioClient.postVoid(
      ApiEndpoints.classAssignmentsReorder(classId),
      data: {'assignment_ids': assignmentIds},
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
