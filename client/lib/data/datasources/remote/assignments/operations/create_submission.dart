import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';

Future<AssignmentSubmissionModel> createSubmission(
  DioClient dioClient, {
  required String assignmentId,
  String? textContent,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.assignmentSubmit(assignmentId),
      data: {'text_content': textContent},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
