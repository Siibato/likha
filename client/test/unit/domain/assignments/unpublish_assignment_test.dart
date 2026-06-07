import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/usecases/unpublish_assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late UnpublishAssignment useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = UnpublishAssignment(mockRepository);
  });

  group('UnpublishAssignment', () {
    const tAssignmentId = 'assignment-1';
    final tUnpublishedAssignment = Assignment(
      id: tAssignmentId,
      classId: 'class-1',
      title: 'Test Assignment',
      instructions: 'Complete the exercises',
      totalPoints: 100,
      allowsTextSubmission: true,
      allowsFileSubmission: false,
      dueAt: DateTime(2024, 12, 31),
      isPublished: false,
      orderIndex: 0,
      submissionCount: 0,
      gradedCount: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('should unpublish assignment successfully', () async {
      when(() => mockRepository.unpublishAssignment(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Right(tUnpublishedAssignment));

      final result = await useCase(tAssignmentId);

      expect(result, Right(tUnpublishedAssignment));
      expect(result.getOrElse(() => throw Exception()).isPublished, false);
      verify(() => mockRepository.unpublishAssignment(assignmentId: tAssignmentId)).called(1);
    });

    test('should return ServerFailure when assignment not found', () async {
      when(() => mockRepository.unpublishAssignment(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => const Left(ServerFailure('Assignment not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when submissions already exist', () async {
      when(() => mockRepository.unpublishAssignment(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => const Left(ValidationFailure('Cannot unpublish assignment with existing submissions')));

      final result = await useCase(tAssignmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.unpublishAssignment(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tAssignmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.unpublishAssignment(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tAssignmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
