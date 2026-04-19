import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/usecases/reorder_assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late ReorderAllAssignments useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = ReorderAllAssignments(mockRepository);
  });

  group('ReorderAllAssignments', () {
    final tClassId = 'class-1';
    final tAssignmentIds = [
      'assignment-3',
      'assignment-1',
      'assignment-2',
    ];

    test('should reorder assignments successfully', () async {
      when(() => mockRepository.reorderAllAssignments(
        classId: any(named: 'classId'),
        assignmentIds: any(named: 'assignmentIds'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        classId: tClassId,
        assignmentIds: tAssignmentIds,
      );

      expect(result.isRight(), true);
      verify(() => mockRepository.reorderAllAssignments(
        classId: tClassId,
        assignmentIds: tAssignmentIds,
      )).called(1);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.reorderAllAssignments(
        classId: any(named: 'classId'),
        assignmentIds: any(named: 'assignmentIds'),
      )).thenAnswer((_) async => Left(ServerFailure('Class not found')));

      final result = await useCase(
        classId: 'nonexistent-class',
        assignmentIds: tAssignmentIds,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when assignmentIds list is empty', () async {
      when(() => mockRepository.reorderAllAssignments(
        classId: any(named: 'classId'),
        assignmentIds: any(named: 'assignmentIds'),
      )).thenAnswer((_) async => Left(ValidationFailure('Assignment IDs list cannot be empty')));

      final result = await useCase(
        classId: tClassId,
        assignmentIds: [],
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.reorderAllAssignments(
        classId: any(named: 'classId'),
        assignmentIds: any(named: 'assignmentIds'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(
        classId: tClassId,
        assignmentIds: tAssignmentIds,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.reorderAllAssignments(
        classId: any(named: 'classId'),
        assignmentIds: any(named: 'assignmentIds'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(
        classId: tClassId,
        assignmentIds: tAssignmentIds,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
