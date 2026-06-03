import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';

Future<AssignmentSubmissionModel> submitAssignment(
  DioClient dioClient, {
  required String submissionId,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.assignmentSubmissionSubmit(submissionId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
