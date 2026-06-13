import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<List<UserModel>> searchStudents(
  DioClient dioClient, {
  String? query,
}) async {
  try {
    return await dioClient.getTyped(
      ApiEndpoints.searchStudents,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
