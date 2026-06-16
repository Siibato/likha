import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';

Future<GradeItemModel> createGradeItem(
  DioClient dioClient, {
  required String classId,
  required Map<String, dynamic> data,
  String? idempotencyKey,
}) async {
  try {
    final response = await dioClient.dio.post(
      ApiEndpoints.gradeItems(classId).path,
      data: data,
      options: idempotencyKey != null
          ? Options(headers: {'Idempotency-Key': idempotencyKey})
          : null,
    );
    final responseData = response.data['data'] ?? response.data;
    return GradeItemModel.fromJson(responseData as Map<String, dynamic>);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
