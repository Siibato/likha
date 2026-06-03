import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late AddQuestions useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = AddQuestions(mockRepository);
  });

  group('AddQuestions', () {
    const tAssessmentId = 'assessment-1';
    const tQuestionsData = [
      {'text': 'What is 2+2?', 'type': 'multiple_choice', 'points': 1},
      {'text': 'Explain your answer', 'type': 'essay', 'points': 5},
    ];
    final tCreatedQuestions = [
      Question(
        id: 'q-1',
        assessmentId: tAssessmentId,
        questionText: 'What is 2+2?',
        questionType: 'multiple_choice',
        orderIndex: 0,
        points: 1,
        isMultiSelect: false,
        choices: const [],
        correctAnswers: const [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Question(
        id: 'q-2',
        assessmentId: tAssessmentId,
        questionText: 'Explain your answer',
        questionType: 'essay',
        orderIndex: 1,
        points: 5,
        isMultiSelect: false,
        choices: null,
        correctAnswers: null,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

    test('should add questions successfully', () async {
      final params = AddQuestionsParams(
        assessmentId: tAssessmentId,
        questions: tQuestionsData,
      );

      when(() => mockRepository.addQuestions(
        assessmentId: any(named: 'assessmentId'),
        questions: any(named: 'questions'),
      )).thenAnswer((_) async => Right(tCreatedQuestions));

      final result = await useCase(params);

      expect(result, Right(tCreatedQuestions));
      expect(result.getOrElse(() => []).length, 2);
      verify(() => mockRepository.addQuestions(
        assessmentId: tAssessmentId,
        questions: tQuestionsData,
      )).called(1);
    });

    test('should return ServerFailure when assessment not found', () async {
      final params = AddQuestionsParams(
        assessmentId: 'nonexistent-id',
        questions: tQuestionsData,
      );

      when(() => mockRepository.addQuestions(
        assessmentId: any(named: 'assessmentId'),
        questions: any(named: 'questions'),
      )).thenAnswer((_) async => const Left(ServerFailure('Assessment not found')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when invalid question data', () async {
      final params = AddQuestionsParams(
        assessmentId: tAssessmentId,
        questions: [],
      );

      when(() => mockRepository.addQuestions(
        assessmentId: any(named: 'assessmentId'),
        questions: any(named: 'questions'),
      )).thenAnswer((_) async => const Left(ValidationFailure('At least one question required')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      final params = AddQuestionsParams(
        assessmentId: tAssessmentId,
        questions: tQuestionsData,
      );

      when(() => mockRepository.addQuestions(
        assessmentId: any(named: 'assessmentId'),
        questions: any(named: 'questions'),
      )).thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      final params = AddQuestionsParams(
        assessmentId: tAssessmentId,
        questions: tQuestionsData,
      );

      when(() => mockRepository.addQuestions(
        assessmentId: any(named: 'assessmentId'),
        questions: any(named: 'questions'),
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
