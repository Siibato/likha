import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/activate_account.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/auth/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ActivateAccount useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ActivateAccount(mockRepository);
  });

  group('ActivateAccount', () {
    final tUser = User(
      id: 'user-1',
      username: 'testuser',
      fullName: 'Test User',
      role: 'student',
      accountStatus: 'activated',
      isActive: true,
      activatedAt: DateTime(2024, 1, 15),
      createdAt: DateTime(2024, 1, 1),
    );

    final tParams = ActivateAccountParams(
      username: 'testuser',
      password: 'password123',
      confirmPassword: 'password123',
    );

    test('should return activated User when activation succeeds', () async {
      when(() => mockRepository.activateAccount(
        username: any(named: 'username'),
        password: any(named: 'password'),
        confirmPassword: any(named: 'confirmPassword'),
      )).thenAnswer((_) async => Right(tUser));

      final result = await useCase(tParams);

      expect(result, Right(tUser));
      expect(result.getOrElse(() => throw Exception()).isActivated, true);
      verify(() => mockRepository.activateAccount(
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      )).called(1);
    });

    test('should return ValidationFailure when passwords do not match', () async {
      final paramsMismatch = ActivateAccountParams(
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'different123',
      );

      when(() => mockRepository.activateAccount(
        username: any(named: 'username'),
        password: any(named: 'password'),
        confirmPassword: any(named: 'confirmPassword'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Passwords do not match')));

      final result = await useCase(paramsMismatch);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when password is too weak', () async {
      final paramsWeak = ActivateAccountParams(
        username: 'testuser',
        password: '123',
        confirmPassword: '123',
      );

      when(() => mockRepository.activateAccount(
        username: any(named: 'username'),
        password: any(named: 'password'),
        confirmPassword: any(named: 'confirmPassword'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Password too weak')));

      final result = await useCase(paramsWeak);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when user not found', () async {
      when(() => mockRepository.activateAccount(
        username: any(named: 'username'),
        password: any(named: 'password'),
        confirmPassword: any(named: 'confirmPassword'),
      )).thenAnswer((_) async => const Left(ServerFailure('User not found')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
