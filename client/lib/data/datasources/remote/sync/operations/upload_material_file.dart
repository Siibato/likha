import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/utils/upload_timeout_util.dart';

Future<Map<String, dynamic>?> uploadMaterialFile(
  DioClient dioClient, {
  required String materialId,
  required String localPath,
  required String fileName,
  String? idempotencyKey,
}) async {
  try {
    RepoLogger.instance.log('uploadMaterialFile: material_id=${materialId.substring(0, 8)} file=$fileName idempotencyKey=${idempotencyKey?.substring(0, 8) ?? "none"}');

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(localPath, filename: fileName),
    });

    final timeoutSeconds = UploadTimeoutUtil.calculateTimeout(localPath);
    RepoLogger.instance.log('uploadMaterialFile: timeout=$timeoutSeconds seconds');

    final response = await dioClient.dio.post(
      ApiEndpoints.materialUploadFile(materialId).path,
      data: formData,
      options: Options(
        sendTimeout: Duration(seconds: timeoutSeconds),
        receiveTimeout: const Duration(seconds: 60),
        headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
      ),
    );

    RepoLogger.instance.log('uploadMaterialFile: response status=${response.statusCode}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>?;
      final fileData = data?['data'] as Map<String, dynamic>?;
      final serverId = fileData?['id'] as String?;
      RepoLogger.instance.log('uploadMaterialFile: success, server_id=${serverId?.substring(0, 8) ?? "none"}');
      return fileData;
    }
    RepoLogger.instance.warn('uploadMaterialFile: unexpected status code ${response.statusCode}');
    return null;
  } on DioException catch (e) {
    RepoLogger.instance.error('uploadMaterialFile: DioException - ${e.type} ${e.message}');
    throw dioClient.handleError(e);
  }
}
