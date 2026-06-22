import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<UserModel> createAccount(
  DioClient dioClient, {
  required String username,
  required String firstName,
  required String lastName,
  required String role,
  Map<String, dynamic>? learnerDetails,
  Map<String, dynamic>? teacherDetails,
  String? idempotencyKey,
}) async {
  try {
    final data = <String, dynamic>{
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
    };
    if (learnerDetails != null) {
      data['learner_details'] = learnerDetails;
    }
    if (teacherDetails != null) {
      data['teacher_details'] = teacherDetails;
    }
    return await dioClient.postTyped(
      ApiEndpoints.accountsCreate,
      data: data,
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
