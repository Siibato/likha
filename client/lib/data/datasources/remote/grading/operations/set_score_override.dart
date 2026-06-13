import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<void> setScoreOverride(
  DioClient dioClient, {
  required String scoreId,
  required double overrideScore,
}) async {
  try {
    await dioClient.dio.put(
      '${dioClient.dio.options.baseUrl}/grade-scores/$scoreId/override',
      data: {'override_score': overrideScore},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
