import 'package:dio/dio.dart';

import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/tos/melcs_model.dart';

Future<List<MelcEntryModel>> searchMelcs(
  DioClient dioClient, {
  String? subject,
  String? gradeLevel,
  int? termNumber,
  String? query,
  int limit = 30,
  int offset = 0,
}) async {
  try {
    final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
    if (subject != null) queryParams['subject'] = subject;
    if (gradeLevel != null) queryParams['grade_level'] = gradeLevel;
    if (termNumber != null) queryParams['quarter'] = termNumber;
    if (query != null) queryParams['q'] = query;

    final response = await dioClient.dio.get(
      ApiEndpoints.melcsSearch().path,
      queryParameters: queryParams,
    );
    final data = response.data['data'] ?? response.data;
    final items = data['melcs'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
    return items
        .map((e) => MelcEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
