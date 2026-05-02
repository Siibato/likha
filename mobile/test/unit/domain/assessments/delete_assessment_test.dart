import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assessments/usecases/delete_assessment.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late DeleteAssessment useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = DeleteAssessment(mockRepository);
  });

  group('DeleteAssessment', () {
    const tAssessmentId = 'assessment-1';

    test('should delete assessment successfully', () async {
      when(() => mockRepository.deleteAssessment(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(tAssessmentId);

      expect(result.isRight(), true);
      verify(() => mockRepository.deleteAssessment(assessmentId: tAssessmentId)).called(1);
    });

    test('should return ServerFailure when assessment not found', () async {
      when(() => mockRepository.deleteAssessment(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Left(ServerFailure('Assessment not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.deleteAssessment(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tAssessmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when submissions exist', () async {
      when(() => mockRepository.deleteAssessment(assessmentId: any(named: 'assessmentId')))
          .thenAnswer((_) async => const Left(ValidationFailure('Cannot delete assessment with existing submissions')));

      final result = await useCase(tAssessmentId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.deleteAssessment(assessmentId: any(named: 'assessmentId')))
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
