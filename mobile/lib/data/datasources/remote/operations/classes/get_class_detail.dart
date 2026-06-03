import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';

Future<ClassDetailModel> getClassDetail(
  DioClient dioClient, {
  required String classId,
}) async {
  try {
    return await dioClient.getTyped(ApiEndpoints.classDetail(classId));
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
