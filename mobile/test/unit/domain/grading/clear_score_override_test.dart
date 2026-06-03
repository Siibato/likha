import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/clear_score_override.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late ClearScoreOverride useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = ClearScoreOverride(mockRepository);
  });

  group('ClearScoreOverride', () {
    const tScoreId = 'score-1';

    test('should clear score override successfully', () async {
      when(() => mockRepository.clearScoreOverride(scoreId: any(named: 'scoreId')))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(tScoreId);

      expect(result.isRight(), true);
      verify(() => mockRepository.clearScoreOverride(scoreId: tScoreId)).called(1);
    });

    test('should return ServerFailure when score not found', () async {
      when(() => mockRepository.clearScoreOverride(scoreId: any(named: 'scoreId')))
          .thenAnswer((_) async => const Left(ServerFailure('Score not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.clearScoreOverride(scoreId: any(named: 'scoreId')))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tScoreId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.clearScoreOverride(scoreId: any(named: 'scoreId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tScoreId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
