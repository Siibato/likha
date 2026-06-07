import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/usecases/submit_assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late SubmitAssignment useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = SubmitAssignment(mockRepository);
  });

  group('SubmitAssignment', () {
    const tSubmissionId = 'submission-1';
    final tSubmittedSubmission = AssignmentSubmission(
      id: tSubmissionId,
      assignmentId: 'assignment-1',
      studentId: 'student-1',
      studentName: 'Student One',
      textContent: 'My submission text',
      status: 'submitted',
      score: null,
      files: const [],
      submittedAt: DateTime(2024, 1, 15),
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
    );

    test('should submit assignment successfully', () async {
      when(() => mockRepository.submitAssignment(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => Right(tSubmittedSubmission));

      final result = await useCase(tSubmissionId);

      expect(result, Right(tSubmittedSubmission));
      expect(result.getOrElse(() => throw Exception()).status, 'submitted');
      verify(() => mockRepository.submitAssignment(submissionId: tSubmissionId)).called(1);
    });

    test('should return ValidationFailure when already submitted', () async {
      when(() => mockRepository.submitAssignment(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => const Left(ValidationFailure('Already submitted')));

      final result = await useCase(tSubmissionId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when past due date', () async {
      when(() => mockRepository.submitAssignment(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => const Left(ValidationFailure('Past due date')));

      final result = await useCase(tSubmissionId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when submission not found', () async {
      when(() => mockRepository.submitAssignment(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => const Left(ServerFailure('Submission not found')));

      final result = await useCase('nonexistent');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
