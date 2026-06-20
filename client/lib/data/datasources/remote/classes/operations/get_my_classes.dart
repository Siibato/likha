import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/classes/class_model.dart';

Future<List<ClassModel>> getMyClasses(
  DioClient dioClient,
) async {
  try {
    return await dioClient.getTyped(ApiEndpoints.classes);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
