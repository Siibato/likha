import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/usecases/get_student_assignment_submission.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late GetStudentAssignmentSubmission useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = GetStudentAssignmentSubmission(mockRepository);
  });

  group('GetStudentAssignmentSubmission', () {
    const tParams = GetStudentAssignmentSubmissionParams(
      assignmentId: 'assignment-1',
      studentId: 'student-1',
    );
    const tStatus = StudentAssignmentStatus(
      submissionId: 'submission-1',
      status: 'submitted',
      score: null,
    );

    test('should get student submission status successfully', () async {
      when(() => mockRepository.getStudentAssignmentSubmission(
        assignmentId: any(named: 'assignmentId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => const Right(tStatus));

      final result = await useCase(tParams);

      expect(result, const Right(tStatus));
      expect(result.getOrElse(() => null)?.status, 'submitted');
      verify(() => mockRepository.getStudentAssignmentSubmission(
        assignmentId: 'assignment-1',
        studentId: 'student-1',
      )).called(1);
    });

    test('should return null when no submission exists', () async {
      when(() => mockRepository.getStudentAssignmentSubmission(
        assignmentId: any(named: 'assignmentId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(tParams);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => null), null);
    });

    test('should return ServerFailure when assignment not found', () async {
      const params = GetStudentAssignmentSubmissionParams(
        assignmentId: 'nonexistent-id',
        studentId: 'student-1',
      );

      when(() => mockRepository.getStudentAssignmentSubmission(
        assignmentId: any(named: 'assignmentId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => const Left(ServerFailure('Assignment not found')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getStudentAssignmentSubmission(
        assignmentId: any(named: 'assignmentId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
