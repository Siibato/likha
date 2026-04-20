import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/usecases/grade_submission.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late GradeSubmission useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = GradeSubmission(mockRepository);
  });

  group('GradeSubmission', () {
    final tParams = GradeSubmissionParams(
      submissionId: 'submission-1',
      score: 85,
      feedback: 'Good work!',
    );
    final tGradedSubmission = AssignmentSubmission(
      id: 'submission-1',
      assignmentId: 'assignment-1',
      studentId: 'student-1',
      studentName: 'Student One',
      textContent: 'Submission text',
      status: 'graded',
      score: 85,
      feedback: 'Good work!',
      files: const [],
      submittedAt: DateTime(2024, 1, 15),
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 16),
    );

    test('should grade submission successfully', () async {
      when(() => mockRepository.gradeSubmission(
        submissionId: any(named: 'submissionId'),
        score: any(named: 'score'),
        feedback: any(named: 'feedback'),
      )).thenAnswer((_) async => Right(tGradedSubmission));

      final result = await useCase(tParams);

      expect(result, Right(tGradedSubmission));
      expect(result.getOrElse(() => throw Exception()).status, 'graded');
      expect(result.getOrElse(() => throw Exception()).score, 85);
      expect(result.getOrElse(() => throw Exception()).feedback, 'Good work!');
      verify(() => mockRepository.gradeSubmission(
        submissionId: 'submission-1',
        score: 85,
        feedback: 'Good work!',
      )).called(1);
    });

    test('should grade without feedback', () async {
      final noFeedbackParams = GradeSubmissionParams(
        submissionId: 'submission-1',
        score: 90,
      );

      final gradedNoFeedback = AssignmentSubmission(
        id: 'submission-1',
        assignmentId: 'assignment-1',
        studentId: 'student-1',
        studentName: 'Student One',
        textContent: 'Submission text',
        status: 'graded',
        score: 90,
        feedback: null,
        files: const [],
        submittedAt: DateTime(2024, 1, 15),
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 16),
      );

      when(() => mockRepository.gradeSubmission(
        submissionId: any(named: 'submissionId'),
        score: any(named: 'score'),
        feedback: any(named: 'feedback'),
      )).thenAnswer((_) async => Right(gradedNoFeedback));

      final result = await useCase(noFeedbackParams);

      expect(result.isRight(), true);
    });

    test('should return ValidationFailure when score out of range', () async {
      final invalidParams = GradeSubmissionParams(
        submissionId: 'submission-1',
        score: 150,
        feedback: 'Invalid score',
      );

      when(() => mockRepository.gradeSubmission(
        submissionId: any(named: 'submissionId'),
        score: any(named: 'score'),
        feedback: any(named: 'feedback'),
      )).thenAnswer((_) async => Left(ValidationFailure('Score out of range')));

      final result = await useCase(invalidParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.gradeSubmission(
        submissionId: any(named: 'submissionId'),
        score: any(named: 'score'),
        feedback: any(named: 'feedback'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
