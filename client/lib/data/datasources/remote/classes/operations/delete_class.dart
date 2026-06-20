import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> deleteClass(
  DioClient dioClient, {
  required String classId,
  String? idempotencyKey,
}) async {
  try {
    await dioClient.deleteTyped(
      ApiEndpoints.classDelete(classId),
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
