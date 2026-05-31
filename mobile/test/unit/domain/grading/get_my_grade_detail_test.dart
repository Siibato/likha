import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/get_my_grade_detail.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late GetMyGradeDetail useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = GetMyGradeDetail(mockRepository);
  });

  group('GetMyGradeDetail', () {
    const tClassId = 'class-1';
    const tPeriod = 1;
    final tDetail = {
      'wwGrade': 80.0,
      'ptGrade': 85.0,
      'qaGrade': 90.0,
      'periodGrade': 84.0,
    };

    test('should get my grade detail successfully', () async {
      when(() => mockRepository.getMyGradeDetail(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
      )).thenAnswer((_) async => Right(tDetail));

      final result = await useCase(classId: tClassId, gradingPeriodNumber: tPeriod);

      expect(result, Right(tDetail));
      verify(() => mockRepository.getMyGradeDetail(
        classId: tClassId,
        gradingPeriodNumber: tPeriod,
      )).called(1);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.getMyGradeDetail(
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
      when(() => mockRepository.getMyGradeDetail(
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
