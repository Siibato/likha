import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';

Future<LearningMaterialModel> updateMaterial(
  DioClient dioClient, {
  required String materialId,
  required Map<String, dynamic> data,
  String? idempotencyKey,
}) async {
  try {
    return await dioClient.putTyped(
      ApiEndpoints.materialUpdate(materialId),
      data: data,
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
