import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/auth_response_model.dart';
import 'package:likha/services/storage_service.dart';

Future<AuthResponseModel> refreshToken(
  DioClient dioClient,
  StorageService storageService,
  String refreshToken,
) async {
  try {
    final authResponse = await dioClient.postTyped(
      ApiEndpoints.refresh,
      data: {'refresh_token': refreshToken},
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
