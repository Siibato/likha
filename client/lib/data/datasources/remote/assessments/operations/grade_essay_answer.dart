import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<SubmissionAnswerModel> gradeEssayAnswer(
  DioClient dioClient, {
  required String answerId,
  required double points,
  String? idempotencyKey,
}) async {
  try {
    return await dioClient.putTyped(
      ApiEndpoints.submissionAnswerGradeEssay(answerId),
      data: {'points': points},
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
