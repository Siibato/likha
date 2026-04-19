import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/get_all_accounts.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/auth/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetAllAccounts useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetAllAccounts(mockRepository);
  });

  group('GetAllAccounts', () {
    final tUsers = [
      User(
        id: 'user-1',
        username: 'teacher1',
        fullName: 'Teacher One',
        role: 'teacher',
        accountStatus: 'activated',
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      ),
      User(
        id: 'user-2',
        username: 'student1',
        fullName: 'Student One',
        role: 'student',
        accountStatus: 'activated',
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      ),
      User(
        id: 'user-3',
        username: 'admin1',
        fullName: 'Admin One',
        role: 'admin',
        accountStatus: 'activated',
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    test('should return list of all accounts when successful', () async {
      when(() => mockRepository.getAllAccounts()).thenAnswer((_) async => Right(tUsers));

      final result = await useCase();

      expect(result, Right(tUsers));
      expect(result.getOrElse(() => []).length, 3);
      verify(() => mockRepository.getAllAccounts()).called(1);
    });

    test('should return empty list when no accounts exist', () async {
      when(() => mockRepository.getAllAccounts()).thenAnswer((_) async => const Right(<User>[]));

      final result = await useCase();

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return CacheFailure when cache is corrupted', () async {
      when(() => mockRepository.getAllAccounts()).thenAnswer((_) async => Left(CacheFailure('Cache error')));

      final result = await useCase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getAllAccounts()).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return NetworkFailure when offline', () async {
      when(() => mockRepository.getAllAccounts()).thenAnswer((_) async => Left(NetworkFailure('Network error')));

      final result = await useCase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
