import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/utils/upload_timeout_util.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';

Future<MaterialFileModel> uploadFile(
  DioClient dioClient, {
  required String materialId,
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
      ApiEndpoints.materialUploadFile(materialId).path,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        sendTimeout: Duration(seconds: timeoutSeconds),
        receiveTimeout: const Duration(seconds: 60),
        headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
      ),
    );
    return MaterialFileModel.fromJson(response.data['data']);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
