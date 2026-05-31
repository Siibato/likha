import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';

Future<void> deleteGradeItem(
  DioClient dioClient, {
  required String id,
}) async {
  try {
    await dioClient.dio.delete(
      dioClient.dio.options.baseUrl + '/grade-items/$id',
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
