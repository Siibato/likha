import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late CreateAssignment useCase;
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
    useCase = CreateAssignment(mockRepository);
  });

  group('CreateAssignment', () {
    final tAssignment = Assignment(
      id: 'new-assignment-1',
      classId: 'class-1',
      title: 'New Assignment',
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

    final tParams = CreateAssignmentParams(
      classId: 'class-1',
      title: 'New Assignment',
      instructions: 'Complete the exercises',
      totalPoints: 100,
      allowsTextSubmission: true,
      allowsFileSubmission: false,
      dueAt: '2024-12-31T23:59:59Z',
      isPublished: true,
    );

    test('should create assignment successfully', () async {
      when(() => mockRepository.createAssignment(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        instructions: any(named: 'instructions'),
        totalPoints: any(named: 'totalPoints'),
        allowsTextSubmission: any(named: 'allowsTextSubmission'),
        allowsFileSubmission: any(named: 'allowsFileSubmission'),
        allowedFileTypes: any(named: 'allowedFileTypes'),
        maxFileSizeMb: any(named: 'maxFileSizeMb'),
        dueAt: any(named: 'dueAt'),
        isPublished: any(named: 'isPublished'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
        noSubmissionRequired: any(named: 'noSubmissionRequired'),
      )).thenAnswer((_) async => Right(tAssignment));

      final result = await useCase(tParams);

      expect(result, Right(tAssignment));
      verify(() => mockRepository.createAssignment(
        classId: 'class-1',
        title: 'New Assignment',
        instructions: 'Complete the exercises',
        totalPoints: 100,
        allowsTextSubmission: true,
        allowsFileSubmission: false,
        allowedFileTypes: null,
        maxFileSizeMb: null,
        dueAt: '2024-12-31T23:59:59Z',
        isPublished: true,
        gradingPeriodNumber: null,
        component: null,
        noSubmissionRequired: null,
      )).called(1);
    });

    test('should create assignment with file submission', () async {
      final fileParams = CreateAssignmentParams(
        classId: 'class-1',
        title: 'File Assignment',
        instructions: 'Upload your file',
        totalPoints: 100,
        allowsTextSubmission: false,
        allowsFileSubmission: true,
        allowedFileTypes: 'pdf,doc,docx',
        maxFileSizeMb: 10,
        dueAt: '2024-12-31T23:59:59Z',
        isPublished: true,
      );

      final fileAssignment = Assignment(
        id: 'file-assignment-1',
        classId: 'class-1',
        title: 'File Assignment',
        instructions: 'Upload your file',
        totalPoints: 100,
        allowsTextSubmission: false,
        allowsFileSubmission: true,
        dueAt: DateTime(2024, 12, 31),
        isPublished: true,
        orderIndex: 0,
        submissionCount: 0,
        gradedCount: 0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      when(() => mockRepository.createAssignment(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        instructions: any(named: 'instructions'),
        totalPoints: any(named: 'totalPoints'),
        allowsTextSubmission: any(named: 'allowsTextSubmission'),
        allowsFileSubmission: any(named: 'allowsFileSubmission'),
        allowedFileTypes: any(named: 'allowedFileTypes'),
        maxFileSizeMb: any(named: 'maxFileSizeMb'),
        dueAt: any(named: 'dueAt'),
        isPublished: any(named: 'isPublished'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
        noSubmissionRequired: any(named: 'noSubmissionRequired'),
      )).thenAnswer((_) async => Right(fileAssignment));

      final result = await useCase(fileParams);

      expect(result.getOrElse(() => throw Exception()).allowsFileSubmission, true);
    });

    test('should return ValidationFailure when validation fails', () async {
      when(() => mockRepository.createAssignment(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        instructions: any(named: 'instructions'),
        totalPoints: any(named: 'totalPoints'),
        allowsTextSubmission: any(named: 'allowsTextSubmission'),
        allowsFileSubmission: any(named: 'allowsFileSubmission'),
        allowedFileTypes: any(named: 'allowedFileTypes'),
        maxFileSizeMb: any(named: 'maxFileSizeMb'),
        dueAt: any(named: 'dueAt'),
        isPublished: any(named: 'isPublished'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
        noSubmissionRequired: any(named: 'noSubmissionRequired'),
      )).thenAnswer((_) async => Left(ValidationFailure('Invalid title')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.createAssignment(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        instructions: any(named: 'instructions'),
        totalPoints: any(named: 'totalPoints'),
        allowsTextSubmission: any(named: 'allowsTextSubmission'),
        allowsFileSubmission: any(named: 'allowsFileSubmission'),
        allowedFileTypes: any(named: 'allowedFileTypes'),
        maxFileSizeMb: any(named: 'maxFileSizeMb'),
        dueAt: any(named: 'dueAt'),
        isPublished: any(named: 'isPublished'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
        noSubmissionRequired: any(named: 'noSubmissionRequired'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
