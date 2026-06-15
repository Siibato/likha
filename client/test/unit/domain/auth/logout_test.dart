import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/logout.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late Logout useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = Logout(mockRepository);
  });

  group('Logout', () {
    test('should complete successfully when logout succeeds', () async {
      when(() => mockRepository.logout()).thenAnswer((_) async => const Right(null));

      final result = await useCase();

      expect(result, const Right(null));
      verify(() => mockRepository.logout()).called(1);
    });

    test('should return failure when logout fails', () async {
      when(() => mockRepository.logout()).thenAnswer((_) async => const Left(CacheFailure('Cache clear failed')));

      final result = await useCase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
