import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/usecases/get_submissions.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late GetAssignmentSubmissions useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = GetAssignmentSubmissions(mockRepository);
  });

  group('GetAssignmentSubmissions', () {
    final tAssignmentId = 'assignment-1';
    final tSubmissions = [
      SubmissionListItem(
        id: 'submission-1',
        studentId: 'student-1',
        studentName: 'Student One',
        studentUsername: 'student1',
        status: 'submitted',
        score: null,
        submittedAt: DateTime(2024, 1, 15),
      ),
      SubmissionListItem(
        id: 'submission-2',
        studentId: 'student-2',
        studentName: 'Student Two',
        studentUsername: 'student2',
        status: 'graded',
        score: 85,
        submittedAt: DateTime(2024, 1, 16),
      ),
    ];

    test('should get submissions successfully', () async {
      when(() => mockRepository.getSubmissions(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Right(tSubmissions));

      final result = await useCase(tAssignmentId);

      expect(result, Right(tSubmissions));
      expect(result.getOrElse(() => []).length, 2);
      verify(() => mockRepository.getSubmissions(assignmentId: tAssignmentId)).called(1);
    });

    test('should return empty list when no submissions exist', () async {
      when(() => mockRepository.getSubmissions(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => const Right(<SubmissionListItem>[]));

      final result = await useCase(tAssignmentId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return ServerFailure when assignment not found', () async {
      when(() => mockRepository.getSubmissions(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Left(ServerFailure('Assignment not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.getSubmissions(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tAssignmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getSubmissions(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tAssignmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
