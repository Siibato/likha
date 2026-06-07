import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoint.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';

Future<void> deleteCompetency(
  DioClient dioClient, {
  required String competencyId,
}) async {
  try {
    await dioClient.deleteTyped(
      ApiEndpoint<void>(
        ApiEndpoints.tosCompetencyDetail(competencyId).path,
        (_) {},
      ),
    );
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
