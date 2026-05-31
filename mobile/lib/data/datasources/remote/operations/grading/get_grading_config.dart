import 'package:dio/dio.dart';

import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';

Future<List<GradeConfigModel>> getGradingConfig(
  DioClient dioClient, {
  required String classId,
}) async {
  try {
    ProviderLogger.instance.debug('getGradingConfig called for classId: $classId');
    final response = await dioClient.dio.get(
      dioClient.dio.options.baseUrl + '/classes/$classId/grading-config',
    );
    ProviderLogger.instance.debug('API response: ${response.data}');
    final raw = response.data['data'] ?? response.data;
    ProviderLogger.instance.debug('raw data: $raw');
    ProviderLogger.instance.debug('raw is List? ${raw is List}');
    ProviderLogger.instance.debug('raw runtime type: ${raw.runtimeType}');
    final configs = raw is List ? raw : (raw['configs'] as List<dynamic>? ?? []);
    ProviderLogger.instance.debug('final configs count: ${configs.length}');
    return configs
        .map((e) => GradeConfigModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
