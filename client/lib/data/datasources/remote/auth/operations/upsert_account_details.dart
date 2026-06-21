import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/account_detail_response_model.dart';

Future<AccountDetailResponseModel> upsertAccountDetails(
  DioClient dioClient, {
  required String userId,
  Map<String, dynamic>? learnerDetails,
  Map<String, dynamic>? teacherDetails,
  String? idempotencyKey,
}) async {
  try {
    return await dioClient.putTyped(
      ApiEndpoints.accountDetails(userId),
      data: {
        if (learnerDetails != null) 'learner_details': learnerDetails,
        if (teacherDetails != null) 'teacher_details': teacherDetails,
      },
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
