import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/save_scores.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late SaveScores useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = SaveScores(mockRepository);
  });

  group('SaveScores', () {
    const tGradeItemId = 'item-1';
    final tScores = [
      {'studentId': 'student-1', 'score': 85.0},
      {'studentId': 'student-2', 'score': 90.0},
    ];

    test('should save scores successfully', () async {
      when(() => mockRepository.saveScores(
        gradeItemId: any(named: 'gradeItemId'),
        scores: any(named: 'scores'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(gradeItemId: tGradeItemId, scores: tScores);

      expect(result.isRight(), true);
      verify(() => mockRepository.saveScores(
        gradeItemId: tGradeItemId,
        scores: tScores,
      )).called(1);
    });

    test('should return ServerFailure when grade item not found', () async {
      when(() => mockRepository.saveScores(
        gradeItemId: any(named: 'gradeItemId'),
        scores: any(named: 'scores'),
      )).thenAnswer((_) async => Left(ServerFailure('Grade item not found')));

      final result = await useCase(gradeItemId: 'nonexistent-id', scores: tScores);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when scores list is empty', () async {
      when(() => mockRepository.saveScores(
        gradeItemId: any(named: 'gradeItemId'),
        scores: any(named: 'scores'),
      )).thenAnswer((_) async => Left(ValidationFailure('Scores list cannot be empty')));

      final result = await useCase(gradeItemId: tGradeItemId, scores: []);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.saveScores(
        gradeItemId: any(named: 'gradeItemId'),
        scores: any(named: 'scores'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(gradeItemId: tGradeItemId, scores: tScores);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.saveScores(
        gradeItemId: any(named: 'gradeItemId'),
        scores: any(named: 'scores'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(gradeItemId: tGradeItemId, scores: tScores);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
