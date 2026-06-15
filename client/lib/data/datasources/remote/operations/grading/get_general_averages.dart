import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/general_average_model.dart';

Future<GeneralAverageResponseModel> getGeneralAverages(
  DioClient dioClient, {
  required String classId,
}) async {
  try {
    final response = await dioClient.dio.get(
      '${dioClient.dio.options.baseUrl}/classes/$classId/general-averages',
    );
    final data = response.data['data'] ?? response.data;
    return GeneralAverageResponseModel.fromJson(
      data as Map<String, dynamic>,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
