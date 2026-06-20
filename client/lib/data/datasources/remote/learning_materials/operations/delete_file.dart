import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> deleteFile(
  DioClient dioClient, {
  required String fileId,
  String? idempotencyKey,
}) async {
  try {
    await dioClient.deleteTyped(
      ApiEndpoints.materialFileDelete(fileId),
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
