import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<void> updateGradeItem(
  DioClient dioClient, {
  required String id,
  required Map<String, dynamic> data,
  String? idempotencyKey,
}) async {
  try {
    await dioClient.dio.put(
      '${dioClient.dio.options.baseUrl}/grade-items/$id',
      data: data,
      options: idempotencyKey != null
          ? Options(headers: {'Idempotency-Key': idempotencyKey})
          : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
