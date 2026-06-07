import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/update_period_grade.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late UpdatePeriodGrade useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = UpdatePeriodGrade(mockRepository);
  });

  group('UpdatePeriodGrade', () {
    const tClassId = 'class-1';
    const tStudentId = 'student-1';
    const tPeriod = 1;
    const tGrade = 88;

    test('should update period grade successfully', () async {
      when(() => mockRepository.updateTransmutedGrade(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        transmutedGrade: any(named: 'transmutedGrade'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        classId: tClassId,
        studentId: tStudentId,
        gradingPeriodNumber: tPeriod,
        transmutedGrade: tGrade,
      );

      expect(result.isRight(), true);
      verify(() => mockRepository.updateTransmutedGrade(
        classId: tClassId,
        studentId: tStudentId,
        gradingPeriodNumber: tPeriod,
        transmutedGrade: tGrade,
      )).called(1);
    });

    test('should return ValidationFailure when grade is out of range', () async {
      when(() => mockRepository.updateTransmutedGrade(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        transmutedGrade: any(named: 'transmutedGrade'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Grade must be between 60 and 100')));

      final result = await useCase(
        classId: tClassId,
        studentId: tStudentId,
        gradingPeriodNumber: tPeriod,
        transmutedGrade: 110,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.updateTransmutedGrade(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        transmutedGrade: any(named: 'transmutedGrade'),
      )).thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(
        classId: tClassId,
        studentId: tStudentId,
        gradingPeriodNumber: tPeriod,
        transmutedGrade: tGrade,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.updateTransmutedGrade(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        transmutedGrade: any(named: 'transmutedGrade'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(
        classId: tClassId,
        studentId: tStudentId,
        gradingPeriodNumber: tPeriod,
        transmutedGrade: tGrade,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
