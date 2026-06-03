import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/sync/push_response_model.dart';

Future<PushResponseModel> pushOperations(
  DioClient dioClient, {
  required List<Map<String, dynamic>> operations,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.syncPush,
      data: {'operations': operations},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
