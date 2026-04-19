import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/usecases/publish_assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late PublishAssignment useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = PublishAssignment(mockRepository);
  });

  group('PublishAssignment', () {
    final tAssignmentId = 'assignment-1';
    final tPublishedAssignment = Assignment(
      id: tAssignmentId,
      classId: 'class-1',
      title: 'Test Assignment',
      instructions: 'Complete the exercises',
      totalPoints: 100,
      allowsTextSubmission: true,
      allowsFileSubmission: false,
      dueAt: DateTime(2024, 12, 31),
      isPublished: true,
      orderIndex: 0,
      submissionCount: 0,
      gradedCount: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('should publish assignment successfully', () async {
      when(() => mockRepository.publishAssignment(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Right(tPublishedAssignment));

      final result = await useCase(tAssignmentId);

      expect(result, Right(tPublishedAssignment));
      expect(result.getOrElse(() => throw Exception()).isPublished, true);
      verify(() => mockRepository.publishAssignment(assignmentId: tAssignmentId)).called(1);
    });

    test('should return ServerFailure when assignment not found', () async {
      when(() => mockRepository.publishAssignment(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Left(ServerFailure('Assignment not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.publishAssignment(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tAssignmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.publishAssignment(assignmentId: any(named: 'assignmentId')))
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
