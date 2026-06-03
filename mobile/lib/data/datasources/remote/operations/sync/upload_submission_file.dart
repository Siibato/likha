import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<Map<String, dynamic>?> uploadSubmissionFile(
  DioClient dioClient, {
  required String submissionId,
  required String localPath,
  required String fileName,
}) async {
  try {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(localPath, filename: fileName),
    });
    final response = await dioClient.dio.post(
      ApiEndpoints.assignmentSubmissionUpload(submissionId).path,
      data: formData,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>?;
      return data?['data'] as Map<String, dynamic>?;
    }
    return null;
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
