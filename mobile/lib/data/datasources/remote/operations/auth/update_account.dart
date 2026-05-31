import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<UserModel> updateAccount(
  DioClient dioClient, {
  required String userId,
  String? fullName,
  String? role,
}) async {
  try {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (role != null) data['role'] = role;

    return await dioClient.putTyped(
      ApiEndpoints.accountUpdate(userId),
      data: data,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
