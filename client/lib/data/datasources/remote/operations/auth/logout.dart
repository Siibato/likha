import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/services/storage_service.dart';

Future<void> logout(
  DioClient dioClient,
  StorageService storageService,
  String refreshToken,
) async {
  try {
    await dioClient.postVoid(
      ApiEndpoints.logout,
      data: {'refresh_token': refreshToken},
    );

    await storageService.clearAuthData();
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
