import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';

Future<AssessmentModel> updateAssessment(
  DioClient dioClient, {
  required String assessmentId,
  required Map<String, dynamic> data,
}) async {
  try {
    return await dioClient.putTyped(
      ApiEndpoints.assessmentDetail(assessmentId),
      data: data,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
