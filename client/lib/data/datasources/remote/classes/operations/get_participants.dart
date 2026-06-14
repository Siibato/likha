import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/api_types.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<List<UserModel>> getParticipants(
  DioClient dioClient, {
  required String classId,
}) async {
  try {
    final endpoint = ApiEndpoint<List<UserModel>>(
      '/api/v1/classes/$classId/students',
      (json) {
        final list = json as List<dynamic>;
        return list
            .map((e) {
              final enrollment = e as Map<String, dynamic>;
              final student = enrollment['student'] as Map<String, dynamic>;
              return UserModel.fromJson(student);
            })
            .toList();
      },
    );
    return await dioClient.getTyped(endpoint);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
