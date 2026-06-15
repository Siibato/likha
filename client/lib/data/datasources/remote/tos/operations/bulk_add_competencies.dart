import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<List<CompetencyModel>> bulkAddCompetencies(
  DioClient dioClient, {
  required String tosId,
  required List<Map<String, dynamic>> competencies,
  String? idempotencyKey,
}) async {
  try {
    return await dioClient.postTyped(
      ApiEndpoints.tosBulkCompetencies(tosId),
      data: {'competencies': competencies},
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
