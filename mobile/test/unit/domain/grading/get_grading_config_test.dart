import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/usecases/get_grading_config.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late GetGradingConfig useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = GetGradingConfig(mockRepository);
  });

  group('GetGradingConfig', () {
    const tClassId = 'class-1';
    final tConfigs = [
      GradeConfig(
        id: 'config-1',
        classId: tClassId,
        gradingPeriodNumber: 1,
        wwWeight: 30.0,
        ptWeight: 50.0,
        qaWeight: 20.0,
      ),
      GradeConfig(
        id: 'config-2',
        classId: tClassId,
        gradingPeriodNumber: 2,
        wwWeight: 30.0,
        ptWeight: 50.0,
        qaWeight: 20.0,
      ),
    ];

    test('should get grading config successfully', () async {
      when(() => mockRepository.getGradingConfig(classId: any(named: 'classId')))
          .thenAnswer((_) async => Right(tConfigs));

      final result = await useCase(tClassId);

      expect(result, Right(tConfigs));
      expect(result.getOrElse(() => []).length, 2);
      verify(() => mockRepository.getGradingConfig(classId: tClassId)).called(1);
    });

    test('should return empty list when no config exists', () async {
      when(() => mockRepository.getGradingConfig(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Right(<GradeConfig>[]));

      final result = await useCase(tClassId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.getGradingConfig(classId: any(named: 'classId')))
          .thenAnswer((_) async => Left(ServerFailure('Class not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getGradingConfig(classId: any(named: 'classId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tClassId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
