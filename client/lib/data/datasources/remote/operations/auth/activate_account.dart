import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/auth_response_model.dart';
import 'package:likha/services/storage_service.dart';

Future<AuthResponseModel> activateAccount(
  DioClient dioClient,
  StorageService storageService, {
  required String username,
  required String password,
  required String confirmPassword,
}) async {
  try {
    final authResponse = await dioClient.postTyped(
      ApiEndpoints.activate,
      data: {
        'username': username,
        'password': password,
        'confirm_password': confirmPassword,
      },
    );

    await storageService.saveAuthData(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      userId: authResponse.user.id,
    );

    return authResponse;
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
