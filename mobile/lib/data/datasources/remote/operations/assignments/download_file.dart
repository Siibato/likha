import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<List<int>> downloadFile(
  DioClient dioClient, {
  required String fileId,
}) async {
  try {
    final response = await dioClient.dio.get(
      ApiEndpoints.submissionFileDownload(fileId).path,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
