import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/tos/usecases/delete_tos.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class MockTosRepository extends Mock implements TosRepository {}

void main() {
  late DeleteTos useCase;
  late MockTosRepository mockRepository;

  setUp(() {
    mockRepository = MockTosRepository();
    useCase = DeleteTos(mockRepository);
  });

  group('DeleteTos', () {
    const tTosId = 'tos-1';

    test('should delete TOS successfully', () async {
      when(() => mockRepository.deleteTos(tosId: any(named: 'tosId')))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(tTosId);

      expect(result.isRight(), true);
      verify(() => mockRepository.deleteTos(tosId: tTosId)).called(1);
    });

    test('should return ServerFailure when TOS not found', () async {
      when(() => mockRepository.deleteTos(tosId: any(named: 'tosId')))
          .thenAnswer((_) async => Left(ServerFailure('TOS not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.deleteTos(tosId: any(named: 'tosId')))
          .thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tTosId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.deleteTos(tosId: any(named: 'tosId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tTosId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
