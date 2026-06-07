import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/usecases/create_submission.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late CreateSubmission useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = CreateSubmission(mockRepository);
  });

  group('CreateSubmission', () {
    const tAssignmentId = 'assignment-1';
    final tSubmission = AssignmentSubmission(
      id: 'submission-1',
      assignmentId: tAssignmentId,
      studentId: 'student-1',
      studentName: 'Student One',
      status: 'draft',
      textContent: 'Draft submission text',
      files: const [],
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
    );

    test('should create submission with text content successfully', () async {
      final params = CreateSubmissionParams(
        assignmentId: tAssignmentId,
        textContent: 'Draft submission text',
      );

      when(() => mockRepository.createSubmission(
        assignmentId: any(named: 'assignmentId'),
        textContent: any(named: 'textContent'),
      )).thenAnswer((_) async => Right(tSubmission));

      final result = await useCase(params);

      expect(result, Right(tSubmission));
      verify(() => mockRepository.createSubmission(
        assignmentId: tAssignmentId,
        textContent: 'Draft submission text',
      )).called(1);
    });

    test('should create submission without text content successfully', () async {
      final params = CreateSubmissionParams(
        assignmentId: tAssignmentId,
      );

      when(() => mockRepository.createSubmission(
        assignmentId: any(named: 'assignmentId'),
        textContent: any(named: 'textContent'),
      )).thenAnswer((_) async => Right(tSubmission));

      final result = await useCase(params);

      expect(result.isRight(), true);
      verify(() => mockRepository.createSubmission(
        assignmentId: tAssignmentId,
        textContent: null,
      )).called(1);
    });

    test('should return ServerFailure when assignment not found', () async {
      final params = CreateSubmissionParams(
        assignmentId: 'nonexistent-id',
        textContent: 'Text',
      );

      when(() => mockRepository.createSubmission(
        assignmentId: any(named: 'assignmentId'),
        textContent: any(named: 'textContent'),
      )).thenAnswer((_) async => const Left(ServerFailure('Assignment not found')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when submission already exists', () async {
      final params = CreateSubmissionParams(
        assignmentId: tAssignmentId,
        textContent: 'Text',
      );

      when(() => mockRepository.createSubmission(
        assignmentId: any(named: 'assignmentId'),
        textContent: any(named: 'textContent'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Submission already exists')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      final params = CreateSubmissionParams(
        assignmentId: tAssignmentId,
        textContent: 'Text',
      );

      when(() => mockRepository.createSubmission(
        assignmentId: any(named: 'assignmentId'),
        textContent: any(named: 'textContent'),
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
