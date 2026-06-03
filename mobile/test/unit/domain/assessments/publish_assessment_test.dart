import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/usecases/publish_assessment.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late PublishAssessment useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = PublishAssessment(mockRepository);
  });

  group('PublishAssessment', () {
    const tAssessmentId = 'assessment-1';
    final tPublishedAssessment = Assessment(
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
      questionCount: 5,
      submissionCount: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('should publish assessment successfully', () async {
      when(() => mockRepository.publishAssessment(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => Right(tPublishedAssessment));

      final result = await useCase(tAssessmentId);

      expect(result, Right(tPublishedAssessment));
      expect(result.getOrElse(() => throw Exception()).isPublished, true);
      verify(() => mockRepository.publishAssessment(assessmentId: tAssessmentId)).called(1);
    });

    test('should return ServerFailure when assessment not found', () async {
      when(() => mockRepository.publishAssessment(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Left(ServerFailure('Assessment not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when no questions', () async {
      when(() => mockRepository.publishAssessment(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Left(ValidationFailure('Cannot publish assessment without questions')));

      final result = await useCase(tAssessmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.publishAssessment(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tAssessmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.publishAssessment(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tAssessmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
