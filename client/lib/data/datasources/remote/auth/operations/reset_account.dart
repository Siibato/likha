import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<UserModel> resetAccount(
  DioClient dioClient, {
  required String userId,
  String? idempotencyKey,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.accountsReset,
      data: {'user_id': userId},
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
