import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/get_final_grades.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late GetFinalGrades useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = GetFinalGrades(mockRepository);
  });

  group('GetFinalGrades', () {
    const tClassId = 'class-1';
    final tFinalGrades = [
      {'studentId': 'student-1', 'finalGrade': 88},
      {'studentId': 'student-2', 'finalGrade': 92},
    ];

    test('should get final grades successfully', () async {
      when(() => mockRepository.getFinalGrades(classId: any(named: 'classId')))
          .thenAnswer((_) async => Right(tFinalGrades));

      final result = await useCase(tClassId);

      expect(result, Right(tFinalGrades));
      expect(result.getOrElse(() => []).length, 2);
      verify(() => mockRepository.getFinalGrades(classId: tClassId)).called(1);
    });

    test('should return empty list when no grades computed', () async {
      when(() => mockRepository.getFinalGrades(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Right(<Map<String, dynamic>>[]));

      final result = await useCase(tClassId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.getFinalGrades(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Left(ServerFailure('Class not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getFinalGrades(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tClassId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
