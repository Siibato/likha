import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/tos/tos_model.dart';

Future<CompetencyModel> updateCompetency(
  DioClient dioClient, {
  required String competencyId,
  required Map<String, dynamic> data,
}) async {
  try {
    return await dioClient.putTyped(
      ApiEndpoints.tosCompetencyDetail(competencyId),
      data: data,
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
