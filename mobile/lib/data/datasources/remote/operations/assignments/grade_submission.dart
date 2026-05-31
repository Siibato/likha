import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';

Future<AssignmentSubmissionModel> gradeSubmission(
  DioClient dioClient, {
  required String submissionId,
  required Map<String, dynamic> data,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.assignmentSubmissionGrade(submissionId),
      data: data,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
