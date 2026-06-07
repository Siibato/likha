import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<SubmissionAnswerModel> overrideAnswer(
  DioClient dioClient, {
  required String answerId,
  required bool isCorrect,
  double? points,
}) async {
  try {
    final data = <String, dynamic>{'is_correct': isCorrect};
    if (points != null) {
      data['points'] = points;
    }
    return await dioClient.putTyped(
      ApiEndpoints.submissionAnswerOverride(answerId),
      data: data,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
