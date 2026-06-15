import 'package:dio/dio.dart';

import 'package:likha/core/network/api_types.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> deleteTos(
  DioClient dioClient, {
  required String tosId,
  String? idempotencyKey,
}) async {
  try {
    await dioClient.deleteTyped(
      ApiEndpoint<void>(
        ApiEndpoints.tosDetail(tosId).path,
        (_) {},
      ),
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
