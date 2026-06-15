import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<void> setScoreOverride(
  DioClient dioClient, {
  required String scoreId,
  required double overrideScore,
  String? idempotencyKey,
}) async {
  try {
    await dioClient.dio.put(
      '${dioClient.dio.options.baseUrl}/grade-scores/$scoreId/override',
      data: {'override_score': overrideScore},
      options: idempotencyKey != null
          ? Options(headers: {'Idempotency-Key': idempotencyKey})
          : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
