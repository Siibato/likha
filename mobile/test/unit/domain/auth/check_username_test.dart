import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/check_username.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/auth/entities/check_username_result.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late CheckUsername useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = CheckUsername(mockRepository);
  });

  group('CheckUsername', () {
    const tUsername = 'testuser';

    test('should return pending activation status for new user', () async {
      final tResult = CheckUsernameResult(
        username: tUsername,
        accountStatus: 'pending_activation',
        fullName: 'Test User',
      );

      when(() => mockRepository.checkUsername(username: any(named: 'username')))
          .thenAnswer((_) async => Right(tResult));

      final result = await useCase(tUsername);

      expect(result, Right(tResult));
      expect(result.getOrElse(() => throw Exception()).isPendingActivation, true);
      verify(() => mockRepository.checkUsername(username: tUsername)).called(1);
    });

    test('should return activated status for existing active user', () async {
      final tResult = CheckUsernameResult(
        username: tUsername,
        accountStatus: 'activated',
        fullName: 'Test User',
      );

      when(() => mockRepository.checkUsername(username: any(named: 'username')))
          .thenAnswer((_) async => Right(tResult));

      final result = await useCase(tUsername);

      expect(result, Right(tResult));
      expect(result.getOrElse(() => throw Exception()).isActivated, true);
    });

    test('should return locked status for locked account', () async {
      final tResult = CheckUsernameResult(
        username: tUsername,
        accountStatus: 'locked',
        fullName: 'Test User',
      );

      when(() => mockRepository.checkUsername(username: any(named: 'username')))
          .thenAnswer((_) async => Right(tResult));

      final result = await useCase(tUsername);

      expect(result, Right(tResult));
      expect(result.getOrElse(() => throw Exception()).isLocked, true);
    });

    test('should return ServerFailure when server returns error', () async {
      when(() => mockRepository.checkUsername(username: any(named: 'username')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tUsername);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
