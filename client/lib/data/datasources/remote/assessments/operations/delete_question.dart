import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> deleteQuestion(
  DioClient dioClient, {
  required String questionId,
  String? idempotencyKey,
}) async {
  try {
    await dioClient.deleteTyped(
      ApiEndpoints.questionDetail(questionId),
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
