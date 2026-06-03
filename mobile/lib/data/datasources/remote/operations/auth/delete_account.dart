import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> deleteAccount(
  DioClient dioClient, {
  required String userId,
}) async {
  try {
    await dioClient.deleteTyped(ApiEndpoints.accountDelete(userId));
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
