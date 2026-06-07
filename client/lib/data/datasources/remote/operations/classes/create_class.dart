import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/classes/class_model.dart';

Future<ClassModel> createClass(
  DioClient dioClient, {
  required String title,
  String? description,
  String? teacherId,
  bool isAdvisory = false,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.classCreate,
      data: {
        'title': title,
        if (description != null) 'description': description,
        if (teacherId != null) 'teacher_id': teacherId,
        'is_advisory': isAdvisory,
      },
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
