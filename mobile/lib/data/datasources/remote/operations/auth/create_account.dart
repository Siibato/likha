import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<UserModel> createAccount(
  DioClient dioClient, {
  required String username,
  required String fullName,
  required String role,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.accountsCreate,
      data: {
        'username': username,
        'full_name': fullName,
        'role': role,
      },
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
