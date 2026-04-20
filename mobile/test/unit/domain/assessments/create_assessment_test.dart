import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late CreateAssessment useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = CreateAssessment(mockRepository);
  });

  group('CreateAssessment', () {
    final tClassId = 'class-1';
    final tCreatedAssessment = Assessment(
      id: 'new-assessment-1',
      classId: tClassId,
      title: 'New Assessment',
      description: 'Assessment description',
      timeLimitMinutes: 60,
      openAt: DateTime(2024, 1, 1),
      closeAt: DateTime(2024, 12, 31),
      showResultsImmediately: true,
      resultsReleased: false,
      isPublished: false,
      orderIndex: 0,
      totalPoints: 10,
      questionCount: 0,
      submissionCount: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should create assessment successfully', () async {
      final params = CreateAssessmentParams(
        classId: tClassId,
        title: 'New Assessment',
        description: 'Assessment description',
        timeLimitMinutes: 60,
        openAt: DateTime(2024, 1, 1).toIso8601String(),
        closeAt: DateTime(2024, 12, 31).toIso8601String(),
        showResultsImmediately: true,
        isPublished: false,
      );

      when(() => mockRepository.createAssessment(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        timeLimitMinutes: any(named: 'timeLimitMinutes'),
        openAt: any(named: 'openAt'),
        closeAt: any(named: 'closeAt'),
        showResultsImmediately: any(named: 'showResultsImmediately'),
        isPublished: any(named: 'isPublished'),
        questions: any(named: 'questions'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
        tosId: any(named: 'tosId'),
      )).thenAnswer((_) async => Right(tCreatedAssessment));

      final result = await useCase(params);

      expect(result, Right(tCreatedAssessment));
      expect(result.getOrElse(() => throw Exception()).title, 'New Assessment');
      verify(() => mockRepository.createAssessment(
        classId: tClassId,
        title: 'New Assessment',
        description: 'Assessment description',
        timeLimitMinutes: 60,
        openAt: DateTime(2024, 1, 1).toIso8601String(),
        closeAt: DateTime(2024, 12, 31).toIso8601String(),
        showResultsImmediately: true,
        isPublished: false,
        questions: null,
        gradingPeriodNumber: null,
        component: null,
        tosId: null,
      )).called(1);
    });

    test('should create assessment with questions', () async {
      final params = CreateAssessmentParams(
        classId: tClassId,
        title: 'Quiz with Questions',
        timeLimitMinutes: 30,
        openAt: DateTime(2024, 1, 1).toIso8601String(),
        closeAt: DateTime(2024, 12, 31).toIso8601String(),
        questions: [
          {'text': 'What is 2+2?', 'type': 'multiple_choice'},
        ],
      );

      when(() => mockRepository.createAssessment(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        timeLimitMinutes: any(named: 'timeLimitMinutes'),
        openAt: any(named: 'openAt'),
        closeAt: any(named: 'closeAt'),
        showResultsImmediately: any(named: 'showResultsImmediately'),
        isPublished: any(named: 'isPublished'),
        questions: any(named: 'questions'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
        tosId: any(named: 'tosId'),
      )).thenAnswer((_) async => Right(tCreatedAssessment));

      final result = await useCase(params);

      expect(result.isRight(), true);
      verify(() => mockRepository.createAssessment(
        classId: tClassId,
        title: 'Quiz with Questions',
        description: null,
        timeLimitMinutes: 30,
        openAt: DateTime(2024, 1, 1).toIso8601String(),
        closeAt: DateTime(2024, 12, 31).toIso8601String(),
        showResultsImmediately: null,
        isPublished: true,
        questions: [
          {'text': 'What is 2+2?', 'type': 'multiple_choice'},
        ],
        gradingPeriodNumber: null,
        component: null,
        tosId: null,
      )).called(1);
    });

    test('should return ValidationFailure when title is empty', () async {
      final params = CreateAssessmentParams(
        classId: tClassId,
        title: '',
        timeLimitMinutes: 60,
        openAt: DateTime(2024, 1, 1).toIso8601String(),
        closeAt: DateTime(2024, 12, 31).toIso8601String(),
      );

      when(() => mockRepository.createAssessment(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        timeLimitMinutes: any(named: 'timeLimitMinutes'),
        openAt: any(named: 'openAt'),
        closeAt: any(named: 'closeAt'),
        showResultsImmediately: any(named: 'showResultsImmediately'),
        isPublished: any(named: 'isPublished'),
        questions: any(named: 'questions'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
        tosId: any(named: 'tosId'),
      )).thenAnswer((_) async => Left(ValidationFailure('Title cannot be empty')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when closeAt is before openAt', () async {
      final params = CreateAssessmentParams(
        classId: tClassId,
        title: 'Invalid Assessment',
        timeLimitMinutes: 60,
        openAt: DateTime(2024, 12, 31).toIso8601String(),
        closeAt: DateTime(2024, 1, 1).toIso8601String(),
      );

      when(() => mockRepository.createAssessment(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        timeLimitMinutes: any(named: 'timeLimitMinutes'),
        openAt: any(named: 'openAt'),
        closeAt: any(named: 'closeAt'),
        showResultsImmediately: any(named: 'showResultsImmediately'),
        isPublished: any(named: 'isPublished'),
        questions: any(named: 'questions'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
        tosId: any(named: 'tosId'),
      )).thenAnswer((_) async => Left(ValidationFailure('Close date must be after open date')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      final params = CreateAssessmentParams(
        classId: tClassId,
        title: 'New Assessment',
        timeLimitMinutes: 60,
        openAt: DateTime(2024, 1, 1).toIso8601String(),
        closeAt: DateTime(2024, 12, 31).toIso8601String(),
      );

      when(() => mockRepository.createAssessment(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        timeLimitMinutes: any(named: 'timeLimitMinutes'),
        openAt: any(named: 'openAt'),
        closeAt: any(named: 'closeAt'),
        showResultsImmediately: any(named: 'showResultsImmediately'),
        isPublished: any(named: 'isPublished'),
        questions: any(named: 'questions'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
        tosId: any(named: 'tosId'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      final params = CreateAssessmentParams(
        classId: tClassId,
        title: 'New Assessment',
        timeLimitMinutes: 60,
        openAt: DateTime(2024, 1, 1).toIso8601String(),
        closeAt: DateTime(2024, 12, 31).toIso8601String(),
      );

      when(() => mockRepository.createAssessment(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        timeLimitMinutes: any(named: 'timeLimitMinutes'),
        openAt: any(named: 'openAt'),
        closeAt: any(named: 'closeAt'),
        showResultsImmediately: any(named: 'showResultsImmediately'),
        isPublished: any(named: 'isPublished'),
        questions: any(named: 'questions'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
        tosId: any(named: 'tosId'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
