import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/usecases/start_assessment.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late StartAssessment useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = StartAssessment(mockRepository);
  });

  group('StartAssessment', () {
    final tParams = StartAssessmentParams(
      assessmentId: 'assessment-1',
      studentId: 'student-1',
      studentName: 'Student One',
      studentUsername: 'student1',
    );
    final tResult = StartSubmissionResult(
      submissionId: 'submission-1',
      startedAt: DateTime(2024, 1, 15),
      questions: [],
    );

    test('should start assessment successfully', () async {
      when(() => mockRepository.startAssessment(
        assessmentId: any(named: 'assessmentId'),
        studentId: any(named: 'studentId'),
        studentName: any(named: 'studentName'),
        studentUsername: any(named: 'studentUsername'),
      )).thenAnswer((_) async => Right(tResult));

      final result = await useCase(tParams);

      expect(result, Right(tResult));
      expect(result.getOrElse(() => throw Exception()).submissionId, 'submission-1');
      verify(() => mockRepository.startAssessment(
        assessmentId: 'assessment-1',
        studentId: 'student-1',
        studentName: 'Student One',
        studentUsername: 'student1',
      )).called(1);
    });

    test('should return ServerFailure when assessment not found', () async {
      final params = StartAssessmentParams(
        assessmentId: 'nonexistent-id',
        studentId: 'student-1',
        studentName: 'Student One',
        studentUsername: 'student1',
      );

      when(() => mockRepository.startAssessment(
        assessmentId: any(named: 'assessmentId'),
        studentId: any(named: 'studentId'),
        studentName: any(named: 'studentName'),
        studentUsername: any(named: 'studentUsername'),
      )).thenAnswer((_) async => Left(ServerFailure('Assessment not found')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when assessment not open', () async {
      when(() => mockRepository.startAssessment(
        assessmentId: any(named: 'assessmentId'),
        studentId: any(named: 'studentId'),
        studentName: any(named: 'studentName'),
        studentUsername: any(named: 'studentUsername'),
      )).thenAnswer((_) async => Left(ValidationFailure('Assessment is not open yet')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when already submitted', () async {
      when(() => mockRepository.startAssessment(
        assessmentId: any(named: 'assessmentId'),
        studentId: any(named: 'studentId'),
        studentName: any(named: 'studentName'),
        studentUsername: any(named: 'studentUsername'),
      )).thenAnswer((_) async => Left(ValidationFailure('Assessment already submitted')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.startAssessment(
        assessmentId: any(named: 'assessmentId'),
        studentId: any(named: 'studentId'),
        studentName: any(named: 'studentName'),
        studentUsername: any(named: 'studentUsername'),
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
