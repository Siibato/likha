import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<void> clearScoreOverride(
  DioClient dioClient, {
  required String scoreId,
}) async {
  try {
    await dioClient.dio.delete(
      dioClient.dio.options.baseUrl + '/grade-scores/$scoreId/override',
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
