import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<UserModel> getCurrentUser(
  DioClient dioClient,
) async {
  try {
    return await dioClient.getTyped(ApiEndpoints.me);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
