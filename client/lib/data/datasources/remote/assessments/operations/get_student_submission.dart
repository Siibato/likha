import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<SubmissionSummaryModel?> getStudentSubmission(
  DioClient dioClient, {
  required String assessmentId,
  required String studentId,
}) async {
  try {
    final response = await dioClient.dio.get(
      '/api/v1/assessments/$assessmentId/students/$studentId/submission',
    );
    if (response.statusCode == 204) {
      return null;
    }
    final data = response.data['data'] as Map<String, dynamic>;
    return SubmissionSummaryModel.fromJson(data);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
