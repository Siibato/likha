import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/create_account.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/auth/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late CreateAccount useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = CreateAccount(mockRepository);
  });

  group('CreateAccount', () {
    final tUser = User(
      id: 'new-user-1',
      username: 'newuser',
      fullName: 'New User',
      role: 'student',
      accountStatus: 'pending_activation',
      isActive: false,
      createdAt: DateTime(2024, 1, 1),
    );

    final tParams = CreateAccountParams(
      username: 'newuser',
      fullName: 'New User',
      role: 'student',
    );

    test('should return created User when account creation succeeds', () async {
      when(() => mockRepository.createAccount(
        username: any(named: 'username'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Right(tUser));

      final result = await useCase(tParams);

      expect(result, Right(tUser));
      expect(result.getOrElse(() => throw Exception()).isPendingActivation, true);
      verify(() => mockRepository.createAccount(
        username: 'newuser',
        fullName: 'New User',
        role: 'student',
      )).called(1);
    });

    test('should create teacher account successfully', () async {
      final teacherUser = User(
        id: 'teacher-1',
        username: 'newteacher',
        fullName: 'New Teacher',
        role: 'teacher',
        accountStatus: 'pending_activation',
        isActive: false,
        createdAt: DateTime(2024, 1, 1),
      );

      final teacherParams = CreateAccountParams(
        username: 'newteacher',
        fullName: 'New Teacher',
        role: 'teacher',
      );

      when(() => mockRepository.createAccount(
        username: any(named: 'username'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Right(teacherUser));

      final result = await useCase(teacherParams);

      expect(result.getOrElse(() => throw Exception()).role, 'teacher');
    });

    test('should return ValidationFailure when username already exists', () async {
      when(() => mockRepository.createAccount(
        username: any(named: 'username'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Left(ValidationFailure('Username already exists')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when role is invalid', () async {
      final invalidParams = CreateAccountParams(
        username: 'newuser',
        fullName: 'New User',
        role: 'superadmin',
      );

      when(() => mockRepository.createAccount(
        username: any(named: 'username'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Left(ValidationFailure('Invalid role')));

      final result = await useCase(invalidParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.createAccount(
        username: any(named: 'username'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
