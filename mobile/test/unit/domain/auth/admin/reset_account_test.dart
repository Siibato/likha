import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/reset_account.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/auth/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ResetAccount useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ResetAccount(mockRepository);
  });

  group('ResetAccount', () {
    final tResetUser = User(
      id: 'user-1',
      username: 'testuser',
      fullName: 'Test User',
      role: 'student',
      accountStatus: 'pending_activation',
      isActive: false,
      createdAt: DateTime(2024, 1, 1),
    );

    test('should return reset User when reset succeeds', () async {
      when(() => mockRepository.resetAccount(userId: any(named: 'userId')))
          .thenAnswer((_) async => Right(tResetUser));

      final result = await useCase('user-1');

      expect(result, Right(tResetUser));
      expect(result.getOrElse(() => throw Exception()).isPendingActivation, true);
      expect(result.getOrElse(() => throw Exception()).isActive, false);
      verify(() => mockRepository.resetAccount(userId: 'user-1')).called(1);
    });

    test('should return ServerFailure when user not found', () async {
      when(() => mockRepository.resetAccount(userId: any(named: 'userId')))
          .thenAnswer((_) async => const Left(ServerFailure('User not found')));

      final result = await useCase('nonexistent-user');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.resetAccount(userId: any(named: 'userId')))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase('user-1');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.resetAccount(userId: any(named: 'userId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase('user-1');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
