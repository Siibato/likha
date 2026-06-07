import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/domain/grading/usecases/get_my_grades.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late GetMyGrades useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = GetMyGrades(mockRepository);
  });

  group('GetMyGrades', () {
    const tClassId = 'class-1';

    test('should get my grades successfully', () async {
      when(() => mockRepository.getMyGrades(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Right(<PeriodGrade>[]));

      final result = await useCase(tClassId);

      expect(result.isRight(), true);
      verify(() => mockRepository.getMyGrades(classId: tClassId)).called(1);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.getMyGrades(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Left(ServerFailure('Class not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getMyGrades(classId: any(named: 'classId')))
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
