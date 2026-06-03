import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/set_score_override.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late SetScoreOverride useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = SetScoreOverride(mockRepository);
  });

  group('SetScoreOverride', () {
    const tScoreId = 'score-1';
    const tOverrideScore = 95.0;

    test('should set score override successfully', () async {
      when(() => mockRepository.setScoreOverride(
        scoreId: any(named: 'scoreId'),
        overrideScore: any(named: 'overrideScore'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(scoreId: tScoreId, overrideScore: tOverrideScore);

      expect(result.isRight(), true);
      verify(() => mockRepository.setScoreOverride(
        scoreId: tScoreId,
        overrideScore: tOverrideScore,
      )).called(1);
    });

    test('should return ValidationFailure when override score is negative', () async {
      when(() => mockRepository.setScoreOverride(
        scoreId: any(named: 'scoreId'),
        overrideScore: any(named: 'overrideScore'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Score cannot be negative')));

      final result = await useCase(scoreId: tScoreId, overrideScore: -5.0);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.setScoreOverride(
        scoreId: any(named: 'scoreId'),
        overrideScore: any(named: 'overrideScore'),
      )).thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(scoreId: tScoreId, overrideScore: tOverrideScore);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.setScoreOverride(
        scoreId: any(named: 'scoreId'),
        overrideScore: any(named: 'overrideScore'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(scoreId: tScoreId, overrideScore: tOverrideScore);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
