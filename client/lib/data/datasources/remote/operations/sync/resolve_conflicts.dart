import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/sync/conflict_model.dart';

Future<ConflictResolutionResponse> resolveConflict(
  DioClient dioClient, {
  required ConflictResolutionRequest request,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.syncResolveConflict,
      data: request.toJson(),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
