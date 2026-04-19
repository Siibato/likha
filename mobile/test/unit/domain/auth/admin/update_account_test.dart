import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/update_account.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/auth/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late UpdateAccount useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = UpdateAccount(mockRepository);
  });

  group('UpdateAccount', () {
    final tUpdatedUser = User(
      id: 'user-1',
      username: 'testuser',
      fullName: 'Updated Name',
      role: 'teacher',
      accountStatus: 'activated',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 15),
    );

    test('should update full name successfully', () async {
      final updateParams = UpdateAccountParams(
        userId: 'user-1',
        fullName: 'Updated Name',
      );

      when(() => mockRepository.updateAccount(
        userId: any(named: 'userId'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Right(tUpdatedUser));

      final result = await useCase(updateParams);

      expect(result, Right(tUpdatedUser));
      expect(result.getOrElse(() => throw Exception()).fullName, 'Updated Name');
      verify(() => mockRepository.updateAccount(
        userId: 'user-1',
        fullName: 'Updated Name',
        role: null,
      )).called(1);
    });

    test('should update role successfully', () async {
      final updateParams = UpdateAccountParams(
        userId: 'user-1',
        role: 'teacher',
      );

      when(() => mockRepository.updateAccount(
        userId: any(named: 'userId'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Right(tUpdatedUser));

      final result = await useCase(updateParams);

      expect(result.getOrElse(() => throw Exception()).role, 'teacher');
    });

    test('should update both name and role successfully', () async {
      final updateParams = UpdateAccountParams(
        userId: 'user-1',
        fullName: 'Updated Name',
        role: 'admin',
      );

      when(() => mockRepository.updateAccount(
        userId: any(named: 'userId'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Right(tUpdatedUser));

      final result = await useCase(updateParams);

      expect(result.isRight(), true);
    });

    test('should return ValidationFailure when role is invalid', () async {
      final updateParams = UpdateAccountParams(
        userId: 'user-1',
        role: 'superadmin',
      );

      when(() => mockRepository.updateAccount(
        userId: any(named: 'userId'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Left(ValidationFailure('Invalid role')));

      final result = await useCase(updateParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when user not found', () async {
      final updateParams = UpdateAccountParams(
        userId: 'nonexistent',
        fullName: 'Updated Name',
      );

      when(() => mockRepository.updateAccount(
        userId: any(named: 'userId'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Left(ServerFailure('User not found')));

      final result = await useCase(updateParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      final updateParams = UpdateAccountParams(
        userId: 'user-1',
        fullName: 'Updated Name',
      );

      when(() => mockRepository.updateAccount(
        userId: any(named: 'userId'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(updateParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
