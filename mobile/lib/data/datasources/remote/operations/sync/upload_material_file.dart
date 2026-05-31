import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> uploadMaterialFile(
  DioClient dioClient, {
  required String materialId,
  required String localPath,
  required String fileName,
}) async {
  try {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(localPath, filename: fileName),
    });
    await dioClient.dio.post(
      ApiEndpoints.materialUploadFile(materialId).path,
      data: formData,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
