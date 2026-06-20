import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';

Future<AssignmentSubmissionModel?> getStudentAssignmentSubmission(
  DioClient dioClient, {
  required String assignmentId,
  required String studentId,
}) async {
  try {
    final response = await dioClient.dio.get(
      '/api/v1/assignments/$assignmentId/students/$studentId/submission',
    );
    if (response.statusCode == 204) {
      return null;
    }
    final data = response.data['data'] as Map<String, dynamic>;
    return AssignmentSubmissionModel.fromJson(data);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
