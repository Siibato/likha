import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/usecases/update_assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late UpdateAssignment useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = UpdateAssignment(mockRepository);
  });

  group('UpdateAssignment', () {
    const tAssignmentId = 'assignment-1';
    final tUpdatedAssignment = Assignment(
      id: tAssignmentId,
      classId: 'class-1',
      title: 'Updated Assignment Title',
      instructions: 'Updated instructions',
      totalPoints: 150,
      allowsTextSubmission: true,
      allowsFileSubmission: true,
      dueAt: DateTime(2024, 12, 31),
      isPublished: true,
      orderIndex: 0,
      submissionCount: 0,
      gradedCount: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('should update assignment successfully', () async {
      final params = UpdateAssignmentParams(
        assignmentId: tAssignmentId,
        title: 'Updated Assignment Title',
        instructions: 'Updated instructions',
        totalPoints: 150,
        allowsTextSubmission: true,
        allowsFileSubmission: true,
      );

      when(() => mockRepository.updateAssignment(
        assignmentId: any(named: 'assignmentId'),
        title: any(named: 'title'),
        instructions: any(named: 'instructions'),
        totalPoints: any(named: 'totalPoints'),
        allowsTextSubmission: any(named: 'allowsTextSubmission'),
        allowsFileSubmission: any(named: 'allowsFileSubmission'),
        allowedFileTypes: any(named: 'allowedFileTypes'),
        maxFileSizeMb: any(named: 'maxFileSizeMb'),
        dueAt: any(named: 'dueAt'),
      )).thenAnswer((_) async => Right(tUpdatedAssignment));

      final result = await useCase(params);

      expect(result, Right(tUpdatedAssignment));
      verify(() => mockRepository.updateAssignment(
        assignmentId: tAssignmentId,
        title: 'Updated Assignment Title',
        instructions: 'Updated instructions',
        totalPoints: 150,
        allowsTextSubmission: true,
        allowsFileSubmission: true,
        allowedFileTypes: null,
        maxFileSizeMb: null,
        dueAt: null,
      )).called(1);
    });

    test('should update only title when partial update', () async {
      final params = UpdateAssignmentParams(
        assignmentId: tAssignmentId,
        title: 'New Title Only',
      );

      when(() => mockRepository.updateAssignment(
        assignmentId: any(named: 'assignmentId'),
        title: any(named: 'title'),
        instructions: any(named: 'instructions'),
        totalPoints: any(named: 'totalPoints'),
        allowsTextSubmission: any(named: 'allowsTextSubmission'),
        allowsFileSubmission: any(named: 'allowsFileSubmission'),
        allowedFileTypes: any(named: 'allowedFileTypes'),
        maxFileSizeMb: any(named: 'maxFileSizeMb'),
        dueAt: any(named: 'dueAt'),
      )).thenAnswer((_) async => Right(tUpdatedAssignment));

      final result = await useCase(params);

      expect(result.isRight(), true);
      verify(() => mockRepository.updateAssignment(
        assignmentId: tAssignmentId,
        title: 'New Title Only',
        instructions: null,
        totalPoints: null,
        allowsTextSubmission: null,
        allowsFileSubmission: null,
        allowedFileTypes: null,
        maxFileSizeMb: null,
        dueAt: null,
      )).called(1);
    });

    test('should return ServerFailure when assignment not found', () async {
      final params = UpdateAssignmentParams(
        assignmentId: 'nonexistent-id',
        title: 'New Title',
      );

      when(() => mockRepository.updateAssignment(
        assignmentId: any(named: 'assignmentId'),
        title: any(named: 'title'),
        instructions: any(named: 'instructions'),
        totalPoints: any(named: 'totalPoints'),
        allowsTextSubmission: any(named: 'allowsTextSubmission'),
        allowsFileSubmission: any(named: 'allowsFileSubmission'),
        allowedFileTypes: any(named: 'allowedFileTypes'),
        maxFileSizeMb: any(named: 'maxFileSizeMb'),
        dueAt: any(named: 'dueAt'),
      )).thenAnswer((_) async => const Left(ServerFailure('Assignment not found')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when invalid data', () async {
      final params = UpdateAssignmentParams(
        assignmentId: tAssignmentId,
        title: '',
      );

      when(() => mockRepository.updateAssignment(
        assignmentId: any(named: 'assignmentId'),
        title: any(named: 'title'),
        instructions: any(named: 'instructions'),
        totalPoints: any(named: 'totalPoints'),
        allowsTextSubmission: any(named: 'allowsTextSubmission'),
        allowsFileSubmission: any(named: 'allowsFileSubmission'),
        allowedFileTypes: any(named: 'allowedFileTypes'),
        maxFileSizeMb: any(named: 'maxFileSizeMb'),
        dueAt: any(named: 'dueAt'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Title cannot be empty')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      final params = UpdateAssignmentParams(
        assignmentId: tAssignmentId,
        title: 'New Title',
      );

      when(() => mockRepository.updateAssignment(
        assignmentId: any(named: 'assignmentId'),
        title: any(named: 'title'),
        instructions: any(named: 'instructions'),
        totalPoints: any(named: 'totalPoints'),
        allowsTextSubmission: any(named: 'allowsTextSubmission'),
        allowsFileSubmission: any(named: 'allowsFileSubmission'),
        allowedFileTypes: any(named: 'allowedFileTypes'),
        maxFileSizeMb: any(named: 'maxFileSizeMb'),
        dueAt: any(named: 'dueAt'),
      )).thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
