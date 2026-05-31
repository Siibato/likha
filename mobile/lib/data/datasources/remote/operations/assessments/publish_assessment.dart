import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';

Future<AssessmentModel> publishAssessment(
  DioClient dioClient, {
  required String assessmentId,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.assessmentPublish(assessmentId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
