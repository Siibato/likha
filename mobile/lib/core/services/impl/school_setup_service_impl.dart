import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likha/core/crypto/setup_crypto.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/domain/setup/entities/school_config.dart';

class SchoolSetupServiceImpl implements SchoolSetupService {
  static const _keyServerUrl = 'school_server_url';
  static const _keySchoolName = 'school_name';
  static const _keySchoolId = 'school_id';

  // Fixed payloads for the two known servers.
  static const _piPayload = '{"url":"http://192.168.1.1:8080","name":"Pi School"}';
  static const _cloudPayload = '{"url":"https://likha.app","name":"Likha Cloud"}';

  final SharedPreferences _prefs;
  final Dio _dio;

  // Derived short codes — computed lazily on first use.
  String? _piCode;
  String? _cloudCode;

  SchoolSetupServiceImpl(this._prefs, this._dio);

  // ---------------------------------------------------------------------------
  // Short code derivation
  // ---------------------------------------------------------------------------

  String _getPiCode() {
    _piCode ??= SetupCrypto.deriveShortCode(_piPayload);
    return _piCode!;
  }

  String _getCloudCode() {
    _cloudCode ??= SetupCrypto.deriveShortCode(_cloudPayload);
    return _cloudCode!;
  }

  // ---------------------------------------------------------------------------
  // SchoolSetupService interface
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, SchoolConfig>> resolveQrPayload(
    String base64Payload,
  ) async {
    try {
      final config = SetupCrypto.decryptQrPayload(base64Payload);
      await saveSchoolConfig(config);
      return Right(config);
    } on SetupCryptoException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ValidationFailure('Invalid QR code'));
    }
  }

  @override
  Future<Either<Failure, SchoolConfig>> resolveShortCode(String code) async {
    final normalized = code.trim().toUpperCase();
    try {
      if (normalized == _getPiCode()) {
        const config = SchoolConfig(
          serverUrl: 'http://192.168.1.1:8080',
          schoolName: 'Pi School',
        );
        await saveSchoolConfig(config);
        return const Right(config);
      }
      if (normalized == _getCloudCode()) {
        const config = SchoolConfig(
          serverUrl: 'https://likha.app',
          schoolName: 'Likha Cloud',
        );
        await saveSchoolConfig(config);
        return const Right(config);
      }
      return const Left(ValidationFailure('Invalid school code. Check the code and try again.'));
    } on SetupCryptoException catch (e) {
      return Left(ValidationFailure(e.message));
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
        return const Left(NetworkFailure('Could not reach the server. Check the URL and your connection.'));
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
