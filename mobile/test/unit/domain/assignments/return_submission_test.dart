import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/usecases/return_submission.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late ReturnSubmission useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = ReturnSubmission(mockRepository);
  });

  group('ReturnSubmission', () {
    final tSubmissionId = 'submission-1';
    final tReturnedSubmission = AssignmentSubmission(
      id: tSubmissionId,
      assignmentId: 'assignment-1',
      studentId: 'student-1',
      studentName: 'Student One',
      status: 'returned',
      textContent: 'Submission text',
      score: 75,
      feedback: 'Please revise and resubmit',
      files: const [],
      submittedAt: DateTime(2024, 1, 15),
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 16),
    );

    test('should return submission successfully', () async {
      when(() => mockRepository.returnSubmission(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => Right(tReturnedSubmission));

      final result = await useCase(tSubmissionId);

      expect(result, Right(tReturnedSubmission));
      expect(result.getOrElse(() => throw Exception()).status, 'returned');
      verify(() => mockRepository.returnSubmission(submissionId: tSubmissionId)).called(1);
    });

    test('should return ServerFailure when submission not found', () async {
      when(() => mockRepository.returnSubmission(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => Left(ServerFailure('Submission not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when submission not graded', () async {
      when(() => mockRepository.returnSubmission(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => Left(ValidationFailure('Submission must be graded before returning')));

      final result = await useCase(tSubmissionId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.returnSubmission(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tSubmissionId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.returnSubmission(submissionId: any(named: 'submissionId')))
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
