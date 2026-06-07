import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<TosModel> createTos(
  DioClient dioClient, {
  required String classId,
  required Map<String, dynamic> data,
}) async {
  try {
    final response = await dioClient.dio.post(
      ApiEndpoints.tosList(classId).path,
      data: data,
    );
    final responseData = response.data['data'] ?? response.data;
    return TosModel.fromJson(responseData as Map<String, dynamic>);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
