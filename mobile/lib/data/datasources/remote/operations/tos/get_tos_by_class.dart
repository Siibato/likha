import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<List<TosModel>> getTosByClass(
  DioClient dioClient, {
  required String classId,
}) async {
  try {
    return await dioClient.getTyped(
      ApiEndpoints.tosList(classId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
