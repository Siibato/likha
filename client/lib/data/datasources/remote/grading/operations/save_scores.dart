import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<void> saveScores(
  DioClient dioClient, {
  required String gradeItemId,
  required List<Map<String, dynamic>> scores,
  String? idempotencyKey,
}) async {
  try {
    await dioClient.dio.put(
      '${dioClient.dio.options.baseUrl}/grade-items/$gradeItemId/scores',
      data: {'scores': scores},
      options: idempotencyKey != null
          ? Options(headers: {'Idempotency-Key': idempotencyKey})
          : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
