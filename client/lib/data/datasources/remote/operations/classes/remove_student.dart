import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> removeStudent(
  DioClient dioClient, {
  required String classId,
  required String studentId,
}) async {
  try {
    await dioClient.deleteTyped(
      ApiEndpoints.classStudent(classId, studentId),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
