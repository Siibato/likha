import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/api_types.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/sync/full_sync_response_model.dart';

Future<FullSyncResponseModel> fullSync(
  DioClient dioClient, {
  required String deviceId,
  List<String> classIds = const [],
  Duration? receiveTimeout,
}) async {
  try {
    final data = {
      'device_id': deviceId,
      if (classIds.isNotEmpty) 'class_ids': classIds,
    };

    if (receiveTimeout != null) {
      final response = await dioClient.dio.post(
        ApiEndpoints.syncFull.path,
        data: data,
        options: Options(receiveTimeout: receiveTimeout),
      );
      final apiResponse = ApiResponse.fromJson(response.data, (json) => FullSyncResponseModel.fromJson(json as Map<String, dynamic>));
      return apiResponse.unwrap();
    } else {
      return await dioClient.postTyped(
        ApiEndpoints.syncFull,
        data: data,
      );
    }
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
