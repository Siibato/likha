import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late GetAssessments useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = GetAssessments(mockRepository);
  });

  group('GetAssessments', () {
    const tClassId = 'class-1';
    final tAssessments = [
      Assessment(
        id: 'assessment-1',
        classId: tClassId,
        title: 'Quiz 1',
        description: 'First quiz',
        timeLimitMinutes: 30,
        openAt: DateTime(2024, 1, 1),
        closeAt: DateTime(2024, 12, 31),
        showResultsImmediately: true,
        resultsReleased: false,
        isPublished: true,
        orderIndex: 0,
        totalPoints: 10,
        questionCount: 5,
        submissionCount: 20,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Assessment(
        id: 'assessment-2',
        classId: tClassId,
        title: 'Quiz 2',
        description: 'Second quiz',
        timeLimitMinutes: 45,
        openAt: DateTime(2024, 2, 1),
        closeAt: DateTime(2024, 12, 31),
        showResultsImmediately: false,
        resultsReleased: false,
        isPublished: false,
        orderIndex: 1,
        totalPoints: 20,
        questionCount: 10,
        submissionCount: 0,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
      ),
    ];

    test('should get all assessments successfully', () async {
      when(() => mockRepository.getAssessments(
        classId: any(named: 'classId'),
        publishedOnly: any(named: 'publishedOnly'),
        skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'),
      )).thenAnswer((_) async => Right(tAssessments));

      final result = await useCase(tClassId);

      expect(result, Right(tAssessments));
      expect(result.getOrElse(() => []).length, 2);
      verify(() => mockRepository.getAssessments(
        classId: tClassId,
        publishedOnly: false,
        skipBackgroundRefresh: false,
      )).called(1);
    });

    test('should filter by published only', () async {
      final publishedAssessments = [tAssessments[0]];

      when(() => mockRepository.getAssessments(
        classId: any(named: 'classId'),
        publishedOnly: any(named: 'publishedOnly'),
        skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'),
      )).thenAnswer((_) async => Right(publishedAssessments));

      final result = await useCase(tClassId, publishedOnly: true);

      expect(result.getOrElse(() => []).length, 1);
      expect(result.getOrElse(() => []).first.isPublished, true);
      verify(() => mockRepository.getAssessments(
        classId: tClassId,
        publishedOnly: true,
        skipBackgroundRefresh: false,
      )).called(1);
    });

    test('should return empty list when no assessments exist', () async {
      when(() => mockRepository.getAssessments(
        classId: any(named: 'classId'),
        publishedOnly: any(named: 'publishedOnly'),
        skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'),
      )).thenAnswer((_) async => const Right(<Assessment>[]));

      final result = await useCase(tClassId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getAssessments(
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

    test('should return NetworkFailure when offline', () async {
      when(() => mockRepository.getAssessments(
        classId: any(named: 'classId'),
        publishedOnly: any(named: 'publishedOnly'),
        skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'),
      )).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

      final result = await useCase(tClassId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
