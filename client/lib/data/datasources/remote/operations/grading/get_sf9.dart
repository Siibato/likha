import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/sf9_model.dart';

Future<Sf9ResponseModel> getSf9(
  DioClient dioClient, {
  required String classId,
  required String studentId,
}) async {
  try {
    final response = await dioClient.dio.get(
      '${dioClient.dio.options.baseUrl}/classes/$classId/students/$studentId/sf9',
    );
    final data = response.data['data'] ?? response.data;
    return Sf9ResponseModel.fromJson(data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
