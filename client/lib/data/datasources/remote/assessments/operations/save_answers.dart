import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> saveAnswers(
  DioClient dioClient, {
  required String submissionId,
  required List<Map<String, dynamic>> answers,
  String? idempotencyKey,
}) async {
  RepoLogger.instance.log('saveAnswers() START - submissionId: $submissionId, answerCount: ${answers.length}');
  try {
    await dioClient.putVoid(
      ApiEndpoints.submissionAnswers(submissionId),
      data: {'answers': answers},
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
    RepoLogger.instance.log('saveAnswers() SUCCESS');
  } on DioException catch (e) {
    RepoLogger.instance.error('saveAnswers() failed', e);
    throw dioClient.handleError(e);
  }
}
