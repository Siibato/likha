import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<List<SubmissionSummaryModel>> getSubmissions(
  DioClient dioClient, {
  required String assessmentId,
}) async {
  try {
    return await dioClient.getTyped(
      ApiEndpoints.assessmentSubmissions(assessmentId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
