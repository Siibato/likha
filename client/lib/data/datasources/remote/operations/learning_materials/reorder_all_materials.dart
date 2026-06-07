import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> reorderAllMaterials(
  DioClient dioClient, {
  required String classId,
  required List<String> materialIds,
}) async {
  try {
    await dioClient.postVoid(
      ApiEndpoints.classMaterialsReorder(classId),
      data: {'material_ids': materialIds},
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
