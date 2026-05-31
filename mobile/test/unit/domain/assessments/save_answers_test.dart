import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assessments/usecases/save_answers.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late SaveAnswers useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = SaveAnswers(mockRepository);
  });

  group('SaveAnswers', () {
    const tSubmissionId = 'submission-1';
    final tAnswers = [
      {'questionId': 'q-1', 'answer': 'option-a'},
      {'questionId': 'q-2', 'answer': 'my essay answer'},
    ];

    test('should save answers successfully', () async {
      final params = SaveAnswersParams(
        submissionId: tSubmissionId,
        answers: tAnswers,
      );

      when(() => mockRepository.saveAnswers(
        submissionId: any(named: 'submissionId'),
        answers: any(named: 'answers'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(params);

      expect(result.isRight(), true);
      verify(() => mockRepository.saveAnswers(
        submissionId: tSubmissionId,
        answers: tAnswers,
      )).called(1);
    });

    test('should save empty answers successfully', () async {
      final params = SaveAnswersParams(
        submissionId: tSubmissionId,
        answers: [],
      );

      when(() => mockRepository.saveAnswers(
        submissionId: any(named: 'submissionId'),
        answers: any(named: 'answers'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(params);

      expect(result.isRight(), true);
      verify(() => mockRepository.saveAnswers(
        submissionId: tSubmissionId,
        answers: [],
      )).called(1);
    });

    test('should return ServerFailure when submission not found', () async {
      final params = SaveAnswersParams(
        submissionId: 'nonexistent-id',
        answers: tAnswers,
      );

      when(() => mockRepository.saveAnswers(
        submissionId: any(named: 'submissionId'),
        answers: any(named: 'answers'),
      )).thenAnswer((_) async => const Left(ServerFailure('Submission not found')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when submission already submitted', () async {
      final params = SaveAnswersParams(
        submissionId: tSubmissionId,
        answers: tAnswers,
      );

      when(() => mockRepository.saveAnswers(
        submissionId: any(named: 'submissionId'),
        answers: any(named: 'answers'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Cannot save answers - assessment already submitted')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      final params = SaveAnswersParams(
        submissionId: tSubmissionId,
        answers: tAnswers,
      );

      when(() => mockRepository.saveAnswers(
        submissionId: any(named: 'submissionId'),
        answers: any(named: 'answers'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
