import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<void> updateGradeItem(
  DioClient dioClient, {
  required String id,
  required Map<String, dynamic> data,
}) async {
  try {
    await dioClient.dio.put(
      dioClient.dio.options.baseUrl + '/grade-items/$id',
      data: data,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
