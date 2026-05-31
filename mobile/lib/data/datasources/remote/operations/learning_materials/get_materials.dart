import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';

Future<List<LearningMaterialModel>> getMaterials(
  DioClient dioClient, {
  required String classId,
}) async {
  try {
    return await dioClient.getTyped(
      ApiEndpoints.classMaterialsList(classId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
