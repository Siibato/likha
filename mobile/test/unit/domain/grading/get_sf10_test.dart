import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/domain/grading/usecases/get_sf10.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late GetSf10 useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = GetSf10(mockRepository);
  });

  group('GetSf10', () {
    final tParams = GetSf10Params(classId: 'class-1', studentId: 'student-1');
    const tSf10 = Sf9Response(
      studentId: 'student-1',
      studentName: 'John Doe',
      gradeLevel: 'Grade 7',
      schoolYear: '2024-2025',
      subjects: [],
    );

    test('should get SF10 successfully', () async {
      when(() => mockRepository.getSf10(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => const Right(tSf10));

      final result = await useCase(tParams);

      expect(result, const Right(tSf10));
      expect(result.getOrElse(() => throw Exception()).studentId, 'student-1');
      verify(() => mockRepository.getSf10(
        classId: 'class-1',
        studentId: 'student-1',
      )).called(1);
    });

    test('should return ServerFailure when student not found', () async {
      when(() => mockRepository.getSf10(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => const Left(ServerFailure('Student not found')));

      final result = await useCase(GetSf10Params(classId: 'class-1', studentId: 'nonexistent'));

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getSf10(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
