import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/services/school_setup_service_impl.dart';

class MockDio extends Mock implements Dio {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SchoolSetupServiceImpl service;
  late MockDio mockDio;
  late MockSharedPreferences mockPrefs;

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://192.168.1.1');
  });

  setUp(() {
    mockDio = MockDio();
    mockPrefs = MockSharedPreferences();
    service = SchoolSetupServiceImpl(mockPrefs, mockDio);

    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);
  });

  group('SchoolSetupService.resolveShortCode', () {
    test('should return ValidationFailure when code is empty', () async {
      final result = await service.resolveShortCode('');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure for whitespace-only code', () async {
      final result = await service.resolveShortCode('   ');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return NetworkFailure on connection timeout', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      final result = await service.resolveShortCode('ABC123');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should use HTTPS fallback when API_BASE_URL is not set', () async {
      // Clear dotenv so the hardcoded fallback is triggered
      dotenv.testLoad(fileInput: '');

      when(() => mockDio.get(
        'https://192.168.1.1/api/v1/setup/verify',
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {'data': {'school_name': 'Test School'}},
      ));

      final result = await service.resolveShortCode('ABC123');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('should be right'),
        (config) => expect(config.serverUrl, 'https://192.168.1.1'),
      );

      // Restore dotenv for subsequent tests
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://192.168.1.1');
    });

    test('should return ValidationFailure on 403 response', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 403,
        ),
      ));

      final result = await service.resolveShortCode('BADCODE');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });

  group('SchoolSetupService.connectManual', () {
    test('should return ValidationFailure when URL is empty', () async {
      final result = await service.connectManual('', 'My School');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when name is empty', () async {
      final result = await service.connectManual('https://192.168.1.1', '');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return NetworkFailure on connection error', () async {
      when(() => mockDio.get(
        any(),
        options: any(named: 'options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));

      final result = await service.connectManual('https://192.168.1.1', 'My School');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });

  group('SchoolSetupService.getSchoolConfig', () {
    test('should return null when no config stored', () async {
      when(() => mockPrefs.getString('school_server_url')).thenReturn(null);
      when(() => mockPrefs.getString('school_name')).thenReturn(null);

      final result = await service.getSchoolConfig();

      expect(result, isNull);
    });

    test('should return SchoolConfig when config is stored', () async {
      when(() => mockPrefs.getString('school_server_url'))
          .thenReturn('https://192.168.1.1');
      when(() => mockPrefs.getString('school_name')).thenReturn('Test School');

      final result = await service.getSchoolConfig();

      expect(result, isNotNull);
      expect(result!.serverUrl, 'https://192.168.1.1');
      expect(result.schoolName, 'Test School');
    });
  });

  group('SchoolSetupService.clearSchoolConfig', () {
    test('should clear all school config keys', () async {
      await service.clearSchoolConfig();

      verify(() => mockPrefs.remove('school_server_url')).called(1);
      verify(() => mockPrefs.remove('school_name')).called(1);
      verify(() => mockPrefs.remove('school_id')).called(1);
    });
  });

  group('SchoolSetupService.resolveQrPayload', () {
    test('should return ValidationFailure for empty QR payload', () async {
      final result = await service.resolveQrPayload('');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
