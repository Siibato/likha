import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<SubmissionAnswerModel> gradeEssayAnswer(
  DioClient dioClient, {
  required String answerId,
  required double points,
}) async {
  try {
    return await dioClient.putTyped(
      ApiEndpoints.submissionAnswerGradeEssay(answerId),
      data: {'points': points},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
