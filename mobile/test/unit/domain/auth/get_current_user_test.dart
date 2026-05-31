import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/get_current_user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/auth/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetCurrentUser useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentUser(mockRepository);
  });

  group('GetCurrentUser', () {
    final tUser = User(
      id: 'user-1',
      username: 'testuser',
      fullName: 'Test User',
      role: 'teacher',
      accountStatus: 'activated',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
    );

    test('should return current user when authenticated', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => Right(tUser));

      final result = await useCase();

      expect(result, Right(tUser));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('should return CacheFailure when no cached user', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => const Left(CacheFailure('No cached user')));

      final result = await useCase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return NetworkFailure when offline and cache miss', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

      final result = await useCase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
