import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<UserModel> updateAccount(
  DioClient dioClient, {
  required String userId,
  String? firstName,
  String? lastName,
  String? role,
  String? idempotencyKey,
}) async {
  try {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (role != null) data['role'] = role;

    return await dioClient.putTyped(
      ApiEndpoints.accountUpdate(userId),
      data: data,
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
