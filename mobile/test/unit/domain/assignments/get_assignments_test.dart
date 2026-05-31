import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late GetAssignments useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = GetAssignments(mockRepository);
  });

  group('GetAssignments', () {
    const tClassId = 'class-1';
    final tAssignments = [
      Assignment(
        id: 'assignment-1',
        classId: tClassId,
        title: 'Assignment 1',
        instructions: 'Do this',
        totalPoints: 100,
        allowsTextSubmission: true,
        allowsFileSubmission: false,
        dueAt: DateTime(2024, 12, 31),
        isPublished: true,
        orderIndex: 0,
        submissionCount: 5,
        gradedCount: 3,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Assignment(
        id: 'assignment-2',
        classId: tClassId,
        title: 'Assignment 2',
        instructions: 'Do that',
        totalPoints: 50,
        allowsTextSubmission: true,
        allowsFileSubmission: true,
        dueAt: DateTime(2024, 12, 31),
        isPublished: false,
        orderIndex: 1,
        submissionCount: 0,
        gradedCount: 0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

    test('should return list of assignments for class', () async {
      when(() => mockRepository.getAssignments(
        classId: any(named: 'classId'),
        publishedOnly: any(named: 'publishedOnly'),
        skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'),
      )).thenAnswer((_) async => Right(tAssignments));

      final result = await useCase(tClassId);

      expect(result, Right(tAssignments));
      expect(result.getOrElse(() => []).length, 2);
      verify(() => mockRepository.getAssignments(
        classId: tClassId,
        publishedOnly: false,
        skipBackgroundRefresh: false,
      )).called(1);
    });

    test('should return only published assignments when publishedOnly is true', () async {
      final publishedAssignments = tAssignments.where((a) => a.isPublished).toList();

      when(() => mockRepository.getAssignments(
        classId: any(named: 'classId'),
        publishedOnly: any(named: 'publishedOnly'),
        skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'),
      )).thenAnswer((_) async => Right(publishedAssignments));

      final result = await useCase(tClassId, publishedOnly: true);

      expect(result.getOrElse(() => []).length, 1);
      expect(result.getOrElse(() => []).first.isPublished, true);
    });

    test('should return empty list when no assignments exist', () async {
      when(() => mockRepository.getAssignments(
        classId: any(named: 'classId'),
        publishedOnly: any(named: 'publishedOnly'),
        skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'),
      )).thenAnswer((_) async => const Right(<Assignment>[]));

      final result = await useCase(tClassId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should skip background refresh when flag is set', () async {
      when(() => mockRepository.getAssignments(
        classId: any(named: 'classId'),
        publishedOnly: any(named: 'publishedOnly'),
        skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'),
      )).thenAnswer((_) async => Right(tAssignments));

      await useCase(tClassId, skipBackgroundRefresh: true);

      verify(() => mockRepository.getAssignments(
        classId: tClassId,
        publishedOnly: false,
        skipBackgroundRefresh: true,
      )).called(1);
    });

    test('should return ServerFailure when repository fails', () async {
      when(() => mockRepository.getAssignments(
        classId: any(named: 'classId'),
        publishedOnly: any(named: 'publishedOnly'),
        skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tClassId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
