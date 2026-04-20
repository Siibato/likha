import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/compute_grades.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late ComputeGrades useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = ComputeGrades(mockRepository);
  });

  group('ComputeGrades', () {
    const tClassId = 'class-1';
    const tPeriod = 1;

    test('should compute grades successfully', () async {
      when(() => mockRepository.computeGrades(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(classId: tClassId, gradingPeriodNumber: tPeriod);

      expect(result.isRight(), true);
      verify(() => mockRepository.computeGrades(
        classId: tClassId,
        gradingPeriodNumber: tPeriod,
      )).called(1);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.computeGrades(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
      )).thenAnswer((_) async => Left(ServerFailure('Class not found')));

      final result = await useCase(classId: 'nonexistent-id', gradingPeriodNumber: tPeriod);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.computeGrades(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(classId: tClassId, gradingPeriodNumber: tPeriod);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.computeGrades(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(classId: tClassId, gradingPeriodNumber: tPeriod);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
