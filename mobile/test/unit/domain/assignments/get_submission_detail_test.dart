import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late GetAssignmentSubmissionDetail useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = GetAssignmentSubmissionDetail(mockRepository);
  });

  group('GetAssignmentSubmissionDetail', () {
    const tSubmissionId = 'submission-1';
    final tSubmission = AssignmentSubmission(
      id: tSubmissionId,
      assignmentId: 'assignment-1',
      studentId: 'student-1',
      studentName: 'Student One',
      status: 'submitted',
      textContent: 'Submission text content',
      score: null,
      files: const [],
      submittedAt: DateTime(2024, 1, 15),
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
    );

    test('should get submission detail successfully', () async {
      when(() => mockRepository.getSubmissionDetail(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => Right(tSubmission));

      final result = await useCase(tSubmissionId);

      expect(result, Right(tSubmission));
      verify(() => mockRepository.getSubmissionDetail(submissionId: tSubmissionId)).called(1);
    });

    test('should return ServerFailure when submission not found', () async {
      when(() => mockRepository.getSubmissionDetail(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => const Left(ServerFailure('Submission not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.getSubmissionDetail(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tSubmissionId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getSubmissionDetail(submissionId: any(named: 'submissionId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tSubmissionId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
