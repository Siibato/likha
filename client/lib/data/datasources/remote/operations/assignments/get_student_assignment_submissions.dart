import 'package:dio/dio.dart';

import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/datasources/remote/models/student_assignment_submission_item_model.dart';

Future<List<StudentAssignmentSubmissionItemModel>> getStudentAssignmentSubmissions(
  DioClient dioClient, {
  required String classId,
  required String studentId,
}) async {
  try {
    final response = await dioClient.dio.get(
      '/api/v1/classes/$classId/students/$studentId/assignment-submissions',
    );
    final items = (response.data['data']['submissions'] as List)
        .cast<Map<String, dynamic>>();
    return items
        .map((item) => StudentAssignmentSubmissionItemModel.fromMap(item))
        .toList();
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
