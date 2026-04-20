import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/lock_account.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/auth/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LockAccount useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LockAccount(mockRepository);
  });

  group('LockAccount', () {
    final tLockedUser = User(
      id: 'user-1',
      username: 'testuser',
      fullName: 'Test User',
      role: 'student',
      accountStatus: 'locked',
      isActive: false,
      createdAt: DateTime(2024, 1, 1),
    );

    final tUnlockedUser = User(
      id: 'user-1',
      username: 'testuser',
      fullName: 'Test User',
      role: 'student',
      accountStatus: 'activated',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
    );

    test('should lock account successfully with reason', () async {
      final lockParams = LockAccountParams(
        userId: 'user-1',
        locked: true,
        reason: 'Violation of terms',
      );

      when(() => mockRepository.lockAccount(
        userId: any(named: 'userId'),
        locked: any(named: 'locked'),
        reason: any(named: 'reason'),
      )).thenAnswer((_) async => Right(tLockedUser));

      final result = await useCase(lockParams);

      expect(result, Right(tLockedUser));
      expect(result.getOrElse(() => throw Exception()).isLocked, true);
      verify(() => mockRepository.lockAccount(
        userId: 'user-1',
        locked: true,
        reason: 'Violation of terms',
      )).called(1);
    });

    test('should lock account without reason', () async {
      final lockParams = LockAccountParams(
        userId: 'user-1',
        locked: true,
      );

      when(() => mockRepository.lockAccount(
        userId: any(named: 'userId'),
        locked: any(named: 'locked'),
        reason: any(named: 'reason'),
      )).thenAnswer((_) async => Right(tLockedUser));

      final result = await useCase(lockParams);

      expect(result.isRight(), true);
    });

    test('should unlock account successfully', () async {
      final unlockParams = LockAccountParams(
        userId: 'user-1',
        locked: false,
      );

      when(() => mockRepository.lockAccount(
        userId: any(named: 'userId'),
        locked: any(named: 'locked'),
        reason: any(named: 'reason'),
      )).thenAnswer((_) async => Right(tUnlockedUser));

      final result = await useCase(unlockParams);

      expect(result, Right(tUnlockedUser));
      expect(result.getOrElse(() => throw Exception()).isActivated, true);
    });

    test('should return ServerFailure when user not found', () async {
      final lockParams = LockAccountParams(
        userId: 'nonexistent',
        locked: true,
      );

      when(() => mockRepository.lockAccount(
        userId: any(named: 'userId'),
        locked: any(named: 'locked'),
        reason: any(named: 'reason'),
      )).thenAnswer((_) async => Left(ServerFailure('User not found')));

      final result = await useCase(lockParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      final lockParams = LockAccountParams(
        userId: 'user-1',
        locked: true,
      );

      when(() => mockRepository.lockAccount(
        userId: any(named: 'userId'),
        locked: any(named: 'locked'),
        reason: any(named: 'reason'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(lockParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
