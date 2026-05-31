import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/get_activity_logs.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetActivityLogs useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetActivityLogs(mockRepository);
  });

  group('GetActivityLogs', () {
    final tLogs = [
      ActivityLog(
        id: 'log-1',
        userId: 'user-1',
        action: 'login',
        details: 'IP: 192.168.1.1',
        createdAt: DateTime(2024, 1, 15, 10, 30),
      ),
      ActivityLog(
        id: 'log-2',
        userId: 'user-1',
        action: 'submit_assignment',
        details: 'Assignment: Math Quiz 1',
        createdAt: DateTime(2024, 1, 15, 11, 0),
      ),
      ActivityLog(
        id: 'log-3',
        userId: 'user-1',
        action: 'logout',
        details: null,
        createdAt: DateTime(2024, 1, 15, 12, 0),
      ),
    ];

    test('should return list of activity logs for user', () async {
      when(() => mockRepository.getActivityLogs(userId: any(named: 'userId')))
          .thenAnswer((_) async => Right(tLogs));

      final result = await useCase('user-1');

      expect(result, Right(tLogs));
      expect(result.getOrElse(() => []).length, 3);
      verify(() => mockRepository.getActivityLogs(userId: 'user-1')).called(1);
    });

    test('should return empty list when no activity logs', () async {
      when(() => mockRepository.getActivityLogs(userId: any(named: 'userId')))
          .thenAnswer((_) async => const Right(<ActivityLog>[]));

      final result = await useCase('user-1');

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return ServerFailure when user not found', () async {
      when(() => mockRepository.getActivityLogs(userId: any(named: 'userId')))
          .thenAnswer((_) async => const Left(ServerFailure('User not found')));

      final result = await useCase('nonexistent');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.getActivityLogs(userId: any(named: 'userId')))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase('user-1');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getActivityLogs(userId: any(named: 'userId')))
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
