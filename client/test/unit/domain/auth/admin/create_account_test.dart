import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
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
      firstName: 'New',
      lastName: 'User',
      role: 'student',
      accountStatus: 'pending_activation',
      isActive: false,
      createdAt: DateTime(2024, 1, 1),
    );

    final tParams = CreateAccountParams(
      username: 'newuser',
      firstName: 'New',
      lastName: 'User',
      role: 'student',
    );

    final tMutationResult = MutationResult(entity: tUser, status: SyncStatus.pending);

    test('should return created User when account creation succeeds', () async {
      when(() => mockRepository.createAccount(
        username: any(named: 'username'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Right(tMutationResult));

      final result = await useCase(tParams);

      expect(result, Right(tMutationResult));
      expect(result.getOrElse(() => throw Exception()).entity.isPendingActivation, true);
      verify(() => mockRepository.createAccount(
        username: 'newuser',
        firstName: 'New',
        lastName: 'User',
        role: 'student',
      )).called(1);
    });

    test('should create teacher account successfully', () async {
      final teacherUser = User(
        id: 'teacher-1',
        username: 'newteacher',
        firstName: 'New',
        lastName: 'Teacher',
        role: 'teacher',
        accountStatus: 'pending_activation',
        isActive: false,
        createdAt: DateTime(2024, 1, 1),
      );

      final teacherParams = CreateAccountParams(
        username: 'newteacher',
        firstName: 'New',
        lastName: 'Teacher',
        role: 'teacher',
      );

      final teacherMutationResult = MutationResult(entity: teacherUser, status: SyncStatus.pending);

      when(() => mockRepository.createAccount(
        username: any(named: 'username'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Right(teacherMutationResult));

      final result = await useCase(teacherParams);

      expect(result.getOrElse(() => throw Exception()).entity.role, 'teacher');
    });

    test('should return ValidationFailure when username already exists', () async {
      when(() => mockRepository.createAccount(
        username: any(named: 'username'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Username already exists')));

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
        firstName: 'New',
        lastName: 'User',
        role: 'superadmin',
      );

      when(() => mockRepository.createAccount(
        username: any(named: 'username'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Invalid role')));

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
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
