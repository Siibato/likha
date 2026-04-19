import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/usecases/get_assessment_detail.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late GetAssessmentDetail useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = GetAssessmentDetail(mockRepository);
  });

  group('GetAssessmentDetail', () {
    final tAssessmentId = 'assessment-1';
    final tAssessment = Assessment(
      id: tAssessmentId,
      classId: 'class-1',
      title: 'Test Assessment',
      description: 'Assessment description',
      timeLimitMinutes: 60,
      openAt: DateTime(2024, 1, 1),
      closeAt: DateTime(2024, 12, 31),
      showResultsImmediately: true,
      resultsReleased: false,
      isPublished: true,
      orderIndex: 0,
      totalPoints: 10,
      questionCount: 2,
      submissionCount: 20,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
    final tQuestions = [
      Question(
        id: 'q-1',
        assessmentId: tAssessmentId,
        questionText: 'What is 2+2?',
        questionType: 'multiple_choice',
        orderIndex: 0,
        points: 1,
        isMultiSelect: false,
        choices: [
          const Choice(id: 'c1', choiceText: '3', isCorrect: false, orderIndex: 0),
          const Choice(id: 'c2', choiceText: '4', isCorrect: true, orderIndex: 1),
        ],
        correctAnswers: const [CorrectAnswer(id: 'a1', answerText: '4')],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Question(
        id: 'q-2',
        assessmentId: tAssessmentId,
        questionText: 'Explain your reasoning',
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

    test('should get assessment detail with questions successfully', () async {
      when(() => mockRepository.getAssessmentDetail(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => Right((tAssessment, tQuestions)));

      final result = await useCase(tAssessmentId);

      expect(result.isRight(), true);
      final (assessment, questions) = result.getOrElse(() => throw Exception());
      expect(assessment.id, tAssessmentId);
      expect(questions.length, 2);
      verify(() => mockRepository.getAssessmentDetail(assessmentId: tAssessmentId)).called(1);
    });

    test('should return ServerFailure when assessment not found', () async {
      when(() => mockRepository.getAssessmentDetail(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => Left(ServerFailure('Assessment not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getAssessmentDetail(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tAssessmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
