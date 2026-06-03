import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/learning_materials/material_detail_model.dart';

Future<MaterialDetailModel> getMaterialDetail(
  DioClient dioClient, {
  required String materialId,
}) async {
  try {
    return await dioClient.getTyped(
      ApiEndpoints.materialDetail(materialId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
