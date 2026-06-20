import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';

Future<ParticipantModel> addStudent(
  DioClient dioClient, {
  required String classId,
  required String studentId,
  String? idempotencyKey,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.classStudents(classId),
      data: {'student_id': studentId},
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
