import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/domain/grading/usecases/get_period_grades.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late GetPeriodGrades useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = GetPeriodGrades(mockRepository);
  });

  group('GetPeriodGrades', () {
    const tClassId = 'class-1';
    const tPeriod = 1;

    test('should get period grades successfully', () async {
      when(() => mockRepository.getPeriodGrades(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
      )).thenAnswer((_) async => const Right(<PeriodGrade>[]));

      final result = await useCase(classId: tClassId, gradingPeriodNumber: tPeriod);

      expect(result.isRight(), true);
      verify(() => mockRepository.getPeriodGrades(
        classId: tClassId,
        gradingPeriodNumber: tPeriod,
      )).called(1);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.getPeriodGrades(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
      )).thenAnswer((_) async => const Left(ServerFailure('Class not found')));

      final result = await useCase(classId: 'nonexistent-id', gradingPeriodNumber: tPeriod);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getPeriodGrades(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(classId: tClassId, gradingPeriodNumber: tPeriod);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
