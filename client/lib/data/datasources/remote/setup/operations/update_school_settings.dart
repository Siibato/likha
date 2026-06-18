import 'package:dio/dio.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/setup/school_settings_model.dart';

Future<SchoolSettingsModel> updateSchoolSettings(
  DioClient dioClient, {
  required String schoolName,
  required String schoolRegion,
  required String schoolDivision,
  required String schoolYear,
  required String schoolCode,
  String? schoolDistrict,
  String? idempotencyKey,
}) async {
  try {
    final options = idempotencyKey != null
        ? Options(headers: {'Idempotency-Key': idempotencyKey})
        : null;
    final response = await dioClient.dio.put(
      '/api/v1/admin/setup/school-settings',
      data: {
        'school_name': schoolName,
        'school_region': schoolRegion,
        'school_division': schoolDivision,
        'school_year': schoolYear,
        'school_code': schoolCode,
        'school_district': schoolDistrict,
      },
      options: options,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SchoolSettingsModel.fromJson(data);
  } on DioException catch (e) {
    throw dioClient.handleError(e);
  }
}
