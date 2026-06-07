import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/classes/class_model.dart';

Future<ClassModel> updateClass(
  DioClient dioClient, {
  required String classId,
  String? title,
  String? description,
  String? teacherId,
  bool? isAdvisory,
}) async {
  try {
    return await dioClient.putTyped(
      ApiEndpoints.classUpdate(classId),
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (teacherId != null) 'teacher_id': teacherId,
        if (isAdvisory != null) 'is_advisory': isAdvisory,
      },
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
