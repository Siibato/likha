import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> reorderAllAssessments(
  DioClient dioClient, {
  required String classId,
  required List<String> assessmentIds,
  String? idempotencyKey,
}) async {
  try {
    await dioClient.postVoid(
      ApiEndpoints.classAssessmentsReorder(classId),
      data: {'assessment_ids': assessmentIds},
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
