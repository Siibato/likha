import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/usecases/delete_assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late DeleteAssignment useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = DeleteAssignment(mockRepository);
  });

  group('DeleteAssignment', () {
    const  tAssignmentId = 'assignment-1';

    test('should delete assignment successfully', () async {
      when(() => mockRepository.deleteAssignment(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(tAssignmentId);

      expect(result.isRight(), true);
      verify(() => mockRepository.deleteAssignment(assignmentId: tAssignmentId)).called(1);
    });

    test('should return ServerFailure when assignment not found', () async {
      when(() => mockRepository.deleteAssignment(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => const Left(ServerFailure('Assignment not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.deleteAssignment(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tAssignmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.deleteAssignment(assignmentId: any(named: 'assignmentId')))
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
