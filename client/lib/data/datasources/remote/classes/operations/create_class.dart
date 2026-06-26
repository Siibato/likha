import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/classes/class_model.dart';

Future<ClassModel> createClass(
  DioClient dioClient, {
  String? id,
  required String title,
  String? description,
  String? teacherId,
  bool isAdvisory = false,
  String? idempotencyKey,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.classCreate,
      data: {
        if (id != null) 'id': id,
        'title': title,
        if (description != null) 'description': description,
        if (teacherId != null) 'teacher_id': teacherId,
        'is_advisory': isAdvisory,
      },
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
