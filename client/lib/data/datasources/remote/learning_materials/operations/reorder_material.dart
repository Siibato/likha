import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';

Future<LearningMaterialModel> reorderMaterial(
  DioClient dioClient, {
  required String materialId,
  required int newOrderIndex,
  String? idempotencyKey,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.materialReorder(materialId),
      data: {'new_order_index': newOrderIndex},
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
