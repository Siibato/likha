import 'package:dio/dio.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/setup/school_settings_model.dart';

Future<SchoolSettingsModel> getSchoolSettings(DioClient dioClient) async {
  try {
    final response = await dioClient.dio.get(
      '/api/v1/admin/setup/school-settings',
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SchoolSettingsModel.fromJson(data);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
