import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<(TosModel, List<CompetencyModel>)> getTosDetail(
  DioClient dioClient, {
  required String tosId,
}) async {
  try {
    final response = await dioClient.dio.get(
      ApiEndpoints.tosDetail(tosId).path,
    );
    final data = response.data['data'] ?? response.data;
    final tos = TosModel.fromJson(data as Map<String, dynamic>);
    final competencies = (data['competencies'] as List<dynamic>? ?? [])
        .map((e) => CompetencyModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (tos, competencies);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
