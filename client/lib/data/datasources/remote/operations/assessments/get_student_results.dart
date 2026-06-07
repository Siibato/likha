import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<StudentResultModel> getStudentResults(
  DioClient dioClient, {
  required String submissionId,
}) async {
  try {
    return await dioClient.getTyped(
      ApiEndpoints.submissionResults(submissionId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
