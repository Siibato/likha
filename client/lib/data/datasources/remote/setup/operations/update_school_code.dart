import 'package:dio/dio.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> updateSchoolCode(
  DioClient dioClient, {
  required String schoolCode,
  String? idempotencyKey,
}) async {
  try {
    final options = idempotencyKey != null
        ? Options(headers: {'Idempotency-Key': idempotencyKey})
        : null;
    await dioClient.dio.put(
      '/api/v1/admin/setup/code',
      data: {'school_code': schoolCode},
      options: options,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
