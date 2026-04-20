import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/delete_account.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late DeleteAccount useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = DeleteAccount(mockRepository);
  });

  group('DeleteAccount', () {
    test('should delete account successfully', () async {
      when(() => mockRepository.deleteAccount(userId: any(named: 'userId')))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(userId: 'user-1');

      expect(result, const Right(null));
      verify(() => mockRepository.deleteAccount(userId: 'user-1')).called(1);
    });

    test('should return ServerFailure when user not found', () async {
      when(() => mockRepository.deleteAccount(userId: any(named: 'userId')))
          .thenAnswer((_) async => Left(ServerFailure('User not found')));

      final result = await useCase(userId: 'nonexistent');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.deleteAccount(userId: any(named: 'userId')))
          .thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(userId: 'user-1');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.deleteAccount(userId: any(named: 'userId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(userId: 'user-1');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
