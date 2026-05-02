import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/usecases/get_scores_by_item.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late GetScoresByItem useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = GetScoresByItem(mockRepository);
  });

  group('GetScoresByItem', () {
    const tGradeItemId = 'item-1';
    final tScores = [
      const GradeScore(
        id: 'score-1',
        gradeItemId: tGradeItemId,
        studentId: 'student-1',
        score: 85.0,
        isAutoPopulated: false,
      ),
      const GradeScore(
        id: 'score-2',
        gradeItemId: tGradeItemId,
        studentId: 'student-2',
        score: 90.0,
        isAutoPopulated: true,
      ),
    ];

    test('should get scores by item successfully', () async {
      when(() => mockRepository.getScoresByItem(gradeItemId: any(named: 'gradeItemId')))
          .thenAnswer((_) async => Right(tScores));

      final result = await useCase(tGradeItemId);

      expect(result, Right(tScores));
      expect(result.getOrElse(() => []).length, 2);
      verify(() => mockRepository.getScoresByItem(gradeItemId: tGradeItemId)).called(1);
    });

    test('should return empty list when no scores exist', () async {
      when(() => mockRepository.getScoresByItem(gradeItemId: any(named: 'gradeItemId')))
          .thenAnswer((_) async => const Right(<GradeScore>[]));

      final result = await useCase(tGradeItemId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return ServerFailure when grade item not found', () async {
      when(() => mockRepository.getScoresByItem(gradeItemId: any(named: 'gradeItemId')))
          .thenAnswer((_) async => const Left(ServerFailure('Grade item not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getScoresByItem(gradeItemId: any(named: 'gradeItemId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tGradeItemId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
