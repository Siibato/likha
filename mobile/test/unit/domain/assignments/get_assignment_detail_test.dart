import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/usecases/get_assignment_detail.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late GetAssignmentDetail useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = GetAssignmentDetail(mockRepository);
  });

  group('GetAssignmentDetail', () {
    final tAssignmentId = 'assignment-1';
    final tAssignment = Assignment(
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
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should get assignment detail successfully', () async {
      when(() => mockRepository.getAssignmentDetail(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Right(tAssignment));

      final result = await useCase(tAssignmentId);

      expect(result, Right(tAssignment));
      verify(() => mockRepository.getAssignmentDetail(assignmentId: tAssignmentId)).called(1);
    });

    test('should return ServerFailure when assignment does not exist', () async {
      when(() => mockRepository.getAssignmentDetail(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Left(ServerFailure('Assignment not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getAssignmentDetail(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tAssignmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return NetworkFailure when offline', () async {
      when(() => mockRepository.getAssignmentDetail(assignmentId: any(named: 'assignmentId')))
          .thenAnswer((_) async => Left(NetworkFailure('Network error')));

      final result = await useCase(tAssignmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
