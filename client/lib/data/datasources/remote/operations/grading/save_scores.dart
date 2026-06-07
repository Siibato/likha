import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<void> saveScores(
  DioClient dioClient, {
  required String gradeItemId,
  required List<Map<String, dynamic>> scores,
}) async {
  try {
    await dioClient.dio.put(
      '${dioClient.dio.options.baseUrl}/grade-items/$gradeItemId/scores',
      data: {'scores': scores},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
