import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/domain/setup/entities/school_config.dart';

class SchoolSetupServiceImpl implements SchoolSetupService {
  static const _keyServerUrl = 'school_server_url';
  static const _keySchoolName = 'school_name';
  static const _keySchoolId = 'school_id';

  final SharedPreferences _prefs;
  final Dio _dio;

  SchoolSetupServiceImpl(this._prefs, this._dio);

  // ---------------------------------------------------------------------------
  // SchoolSetupService interface
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, SchoolConfig>> resolveQrPayload(String payload) async {
    // QR contains the plain school code text — same flow as manual entry
    return resolveShortCode(payload);
  }

  @override
  Future<Either<Failure, SchoolConfig>> resolveShortCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const Left(ValidationFailure('Please enter a school code'));
    }

    // Check if this is the cloud test code (client-side, no server call)
    final cloudTestCode = (dotenv.env['CLOUD_TEST_CODE'] ?? '').toUpperCase();
    if (cloudTestCode.isNotEmpty && normalized == cloudTestCode) {
      final cloudUrl = dotenv.env['CLOUD_API_URL'] ?? 'https://likha.app';
      final config = SchoolConfig(serverUrl: cloudUrl, schoolName: 'Likha Cloud');
      await saveSchoolConfig(config);
      return Right(config);
    }

    // Verify against the default Pi server
    final piUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.1:8080';
    try {
      final response = await _dio.get(
        '$piUrl/api/v1/setup/verify',
        queryParameters: {'code': normalized},
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final schoolName = data?['school_name'] as String? ?? 'My School';
        final config = SchoolConfig(serverUrl: piUrl, schoolName: schoolName);
        await saveSchoolConfig(config);
        return Right(config);
      }
      return const Left(ValidationFailure('Invalid school code'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return const Left(ValidationFailure('Invalid school code. Check the code and try again.'));
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const Left(NetworkFailure(
          'Cannot reach server. Make sure you are connected to school WiFi.',
        ));
      }
      return Left(ServerFailure('Server error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, SchoolConfig>> connectManual(
    String url,
    String name,
  ) async {
    final trimmedUrl = url.trim().replaceAll(RegExp(r'/$'), '');
    final trimmedName = name.trim();

    if (trimmedUrl.isEmpty || trimmedName.isEmpty) {
      return const Left(ValidationFailure('URL and school name are required'));
    }

    try {
      final response = await _dio.get(
        '$trimmedUrl/api/v1/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode == 200) {
        final config = SchoolConfig(serverUrl: trimmedUrl, schoolName: trimmedName);
        await saveSchoolConfig(config);
        return Right(config);
      }
      return const Left(ServerFailure('Server returned an unexpected response'));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const Left(NetworkFailure(
          'Could not reach the server. Check the URL and your connection.',
        ));
      }
      return Left(ServerFailure('Server error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<void> saveSchoolConfig(SchoolConfig config) async {
    await _prefs.setString(_keyServerUrl, config.serverUrl);
    await _prefs.setString(_keySchoolName, config.schoolName);
  }

  @override
  Future<void> clearSchoolConfig() async {
    await _prefs.remove(_keyServerUrl);
    await _prefs.remove(_keySchoolName);
    await _prefs.remove(_keySchoolId);
  }

  @override
  Future<SchoolConfig?> getSchoolConfig() async {
    final url = _prefs.getString(_keyServerUrl);
    final name = _prefs.getString(_keySchoolName);
    if (url == null || name == null) return null;
    return SchoolConfig(serverUrl: url, schoolName: name);
  }
}
