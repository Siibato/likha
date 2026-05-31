import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/usecases/grade_essay.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late GradeEssay useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = GradeEssay(mockRepository);
  });

  group('GradeEssay', () {
    const tAnswerId = 'answer-1';
    const tGradedAnswer = SubmissionAnswer(
      id: tAnswerId,
      questionId: 'q-1',
      questionText: 'What is 2+2?',
      questionType: 'essay',
      points: 5,
      answerText: 'My essay answer',
      pointsAwarded: 4.5,
      isPendingEssayGrade: false,
    );

    test('should grade essay successfully', () async {
      final params = GradeEssayParams(
        answerId: tAnswerId,
        points: 4.5,
      );

      when(() => mockRepository.gradeEssayAnswer(
        answerId: any(named: 'answerId'),
        points: any(named: 'points'),
      )).thenAnswer((_) async => const Right(tGradedAnswer));

      final result = await useCase(params);

      expect(result, const Right(tGradedAnswer));
      expect(result.getOrElse(() => throw Exception()).pointsAwarded, 4.5);
      verify(() => mockRepository.gradeEssayAnswer(
        answerId: tAnswerId,
        points: 4.5,
      )).called(1);
    });

    test('should return ServerFailure when answer not found', () async {
      final params = GradeEssayParams(
        answerId: 'nonexistent-id',
        points: 5.0,
      );

      when(() => mockRepository.gradeEssayAnswer(
        answerId: any(named: 'answerId'),
        points: any(named: 'points'),
      )).thenAnswer((_) async => const Left(ServerFailure('Answer not found')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when points exceed max', () async {
      final params = GradeEssayParams(
        answerId: tAnswerId,
        points: 10.0,
      );

      when(() => mockRepository.gradeEssayAnswer(
        answerId: any(named: 'answerId'),
        points: any(named: 'points'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Points exceed maximum')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      final params = GradeEssayParams(
        answerId: tAnswerId,
        points: 4.0,
      );

      when(() => mockRepository.gradeEssayAnswer(
        answerId: any(named: 'answerId'),
        points: any(named: 'points'),
      )).thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      final params = GradeEssayParams(
        answerId: tAnswerId,
        points: 4.0,
      );

      when(() => mockRepository.gradeEssayAnswer(
        answerId: any(named: 'answerId'),
        points: any(named: 'points'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
