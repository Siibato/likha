import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<UserModel> lockAccount(
  DioClient dioClient, {
  required String userId,
  required bool locked,
  String? reason,
  String? idempotencyKey,
}) async {
  try {
    final data = <String, dynamic>{'user_id': userId, 'locked': locked};
    if (reason != null) data['reason'] = reason;
    return await dioClient.postTyped(
      ApiEndpoints.accountsLock,
      data: data,
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
