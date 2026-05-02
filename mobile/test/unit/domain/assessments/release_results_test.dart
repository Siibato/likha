import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/usecases/release_results.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late ReleaseResults useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = ReleaseResults(mockRepository);
  });

  group('ReleaseResults', () {
    const tAssessmentId = 'assessment-1';
    final tAssessmentWithReleasedResults = Assessment(
      id: tAssessmentId,
      classId: 'class-1',
      title: 'Test Assessment',
      description: 'Assessment description',
      timeLimitMinutes: 60,
      openAt: DateTime(2024, 1, 1),
      closeAt: DateTime(2024, 12, 31),
      showResultsImmediately: false,
      resultsReleased: true,
      isPublished: true,
      orderIndex: 0,
      totalPoints: 10,
      questionCount: 5,
      submissionCount: 20,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('should release results successfully', () async {
      when(() => mockRepository.releaseResults(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => Right(tAssessmentWithReleasedResults));

      final result = await useCase(tAssessmentId);

      expect(result, Right(tAssessmentWithReleasedResults));
      expect(result.getOrElse(() => throw Exception()).resultsReleased, true);
      verify(() => mockRepository.releaseResults(assessmentId: tAssessmentId)).called(1);
    });

    test('should return ServerFailure when assessment not found', () async {
      when(() => mockRepository.releaseResults(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Left(ServerFailure('Assessment not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when results already released', () async {
      when(() => mockRepository.releaseResults(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Left(ValidationFailure('Results already released')));

      final result = await useCase(tAssessmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.releaseResults(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tAssessmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.releaseResults(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tAssessmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
