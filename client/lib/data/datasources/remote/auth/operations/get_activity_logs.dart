import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';

Future<List<ActivityLogModel>> getActivityLogs(
  DioClient dioClient, {
  required String userId,
}) async {
  try {
    return await dioClient.getTyped(ApiEndpoints.accountLogs(userId));
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
