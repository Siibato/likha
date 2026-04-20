import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/usecases/submit_assessment.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late SubmitAssessment useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = SubmitAssessment(mockRepository);
  });

  group('SubmitAssessment', () {
    final tSubmissionId = 'submission-1';
    final tSubmissionSummary = SubmissionSummary(
      id: tSubmissionId,
      assessmentId: 'assessment-1',
      studentId: 'student-1',
      studentName: 'Student One',
      studentUsername: 'student1',
      startedAt: DateTime(2024, 1, 15),
      submittedAt: DateTime(2024, 1, 15),
      autoScore: 0.0,
      finalScore: 0.0,
      totalPoints: 10.0,
      isSubmitted: true,
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
      cachedAt: null,
      needsSync: false,
    );

    test('should submit assessment successfully', () async {
      when(() => mockRepository.submitAssessment(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => Right(tSubmissionSummary));

      final result = await useCase(tSubmissionId);

      expect(result, Right(tSubmissionSummary));
      expect(result.getOrElse(() => throw Exception()).isSubmitted, true);
      verify(() => mockRepository.submitAssessment(submissionId: tSubmissionId)).called(1);
    });

    test('should return ServerFailure when submission not found', () async {
      when(() => mockRepository.submitAssessment(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => Left(ServerFailure('Submission not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when already submitted', () async {
      when(() => mockRepository.submitAssessment(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => Left(ValidationFailure('Assessment already submitted')));

      final result = await useCase(tSubmissionId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when time expired', () async {
      when(() => mockRepository.submitAssessment(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => Left(ValidationFailure('Time limit exceeded')));

      final result = await useCase(tSubmissionId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.submitAssessment(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tSubmissionId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
