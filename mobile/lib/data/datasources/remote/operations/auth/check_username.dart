import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/check_username_result_model.dart';

Future<CheckUsernameResultModel> checkUsername(
  DioClient dioClient, {
  required String username,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.checkUsername,
      data: {'username': username},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
