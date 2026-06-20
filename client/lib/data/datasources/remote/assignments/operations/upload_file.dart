import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/utils/upload_timeout_util.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';

Future<SubmissionFileModel> uploadFile(
  DioClient dioClient, {
  required String submissionId,
  required String filePath,
  required String fileName,
  void Function(int sent, int total)? onSendProgress,
  String? idempotencyKey,
}) async {
  try {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final timeoutSeconds = UploadTimeoutUtil.calculateTimeout(filePath);

    final response = await dioClient.dio.post(
      ApiEndpoints.assignmentSubmissionUpload(submissionId).path,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        sendTimeout: Duration(seconds: timeoutSeconds),
        receiveTimeout: const Duration(seconds: 60),
        headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
      ),
    );
    final responseData = response.data['data'] ?? response.data;
    return SubmissionFileModel.fromJson(responseData);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
