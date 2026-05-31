import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> deleteClass(
  DioClient dioClient, {
  required String classId,
}) async {
  try {
    await dioClient.deleteTyped(
      ApiEndpoints.classDelete(classId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
