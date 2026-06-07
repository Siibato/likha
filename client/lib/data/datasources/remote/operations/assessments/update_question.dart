import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/question_model.dart';

Future<QuestionModel> updateQuestion(
  DioClient dioClient, {
  required String questionId,
  required Map<String, dynamic> data,
}) async {
  try {
    return await dioClient.putTyped(
      ApiEndpoints.questionDetail(questionId),
      data: data,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
