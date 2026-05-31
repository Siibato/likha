import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/question_model.dart';

Future<List<QuestionModel>> addQuestions(
  DioClient dioClient, {
  required String assessmentId,
  required List<Map<String, dynamic>> questions,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.assessmentQuestions(assessmentId),
      data: {'questions': questions},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
