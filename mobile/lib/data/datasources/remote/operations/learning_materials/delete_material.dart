import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> deleteMaterial(
  DioClient dioClient, {
  required String materialId,
}) async {
  try {
    await dioClient.deleteTyped(
      ApiEndpoints.materialDetail(materialId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
