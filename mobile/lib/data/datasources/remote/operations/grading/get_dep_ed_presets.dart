import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<Map<String, dynamic>> getDepEdPresets(
  DioClient dioClient,
) async {
  try {
    final response = await dioClient.dio.get(
      dioClient.dio.options.baseUrl + '/grading-presets/deped',
    );
    return (response.data['data'] ?? response.data) as Map<String, dynamic>;
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
