import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/sync/delta_sync_response_model.dart';

Future<DeltaSyncResponseModel> deltaSync(
  DioClient dioClient, {
  required String deviceId,
  required String lastSyncAt,
  String? dataExpiryAt,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.syncDeltas,
      data: {
        'device_id': deviceId,
        'last_sync_at': lastSyncAt,
        if (dataExpiryAt != null) 'data_expiry_at': dataExpiryAt,
      },
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
