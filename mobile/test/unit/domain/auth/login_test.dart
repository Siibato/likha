import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/login.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/auth/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late Login useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = Login(mockRepository);
  });

  group('Login', () {
    final tUser = User(
      id: 'user-1',
      username: 'testuser',
      fullName: 'Test User',
      role: 'student',
      accountStatus: 'activated',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
    );

    final tParams = LoginParams(
      username: 'testuser',
      password: 'password123',
      deviceId: 'device-1',
    );

    test('should return User when login is successful', () async {
      when(() => mockRepository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
        deviceId: any(named: 'deviceId'),
      )).thenAnswer((_) async => Right(tUser));

      final result = await useCase(tParams);

      expect(result, Right(tUser));
      verify(() => mockRepository.login(
        username: 'testuser',
        password: 'password123',
        deviceId: 'device-1',
      )).called(1);
    });

    test('should return InvalidCredentialsFailure when credentials are invalid', () async {
      when(() => mockRepository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
        deviceId: any(named: 'deviceId'),
      )).thenAnswer((_) async => Left(InvalidCredentialsFailure('Invalid credentials', attemptsRemaining: 3)));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<InvalidCredentialsFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server returns error', () async {
      when(() => mockRepository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
        deviceId: any(named: 'deviceId'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return NetworkFailure when network is unavailable', () async {
      when(() => mockRepository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
        deviceId: any(named: 'deviceId'),
      )).thenAnswer((_) async => Left(NetworkFailure('Network unavailable')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should work without deviceId', () async {
      final paramsWithoutDevice = LoginParams(
        username: 'testuser',
        password: 'password123',
      );

      when(() => mockRepository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
        deviceId: any(named: 'deviceId'),
      )).thenAnswer((_) async => Right(tUser));

      final result = await useCase(paramsWithoutDevice);

      expect(result, Right(tUser));
    });
  });
}
