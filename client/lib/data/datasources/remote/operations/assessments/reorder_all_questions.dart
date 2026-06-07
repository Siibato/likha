import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> reorderAllQuestions(
  DioClient dioClient, {
  required String assessmentId,
  required List<String> questionIds,
}) async {
  try {
    await dioClient.postVoid(
      ApiEndpoints.assessmentQuestionsReorder(assessmentId),
      data: {'question_ids': questionIds},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
