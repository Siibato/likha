import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/account_detail_response_model.dart';

Future<AccountDetailResponseModel> getAccountDetails(
  DioClient dioClient, {
  required String userId,
}) async {
  try {
    return await dioClient.getTyped(
      ApiEndpoints.accountDetails(userId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
