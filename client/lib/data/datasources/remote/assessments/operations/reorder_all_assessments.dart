import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> reorderAllAssessments(
  DioClient dioClient, {
  required String classId,
  required List<String> assessmentIds,
}) async {
  try {
    await dioClient.postVoid(
      ApiEndpoints.classAssessmentsReorder(classId),
      data: {'assessment_ids': assessmentIds},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
