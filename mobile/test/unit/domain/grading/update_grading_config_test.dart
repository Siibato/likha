import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/update_grading_config.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late UpdateGradingConfig useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = UpdateGradingConfig(mockRepository);
  });

  group('UpdateGradingConfig', () {
    const tClassId = 'class-1';
    final tConfigs = [
      {'gradingPeriodNumber': 1, 'wwWeight': 30.0, 'ptWeight': 50.0, 'qaWeight': 20.0},
      {'gradingPeriodNumber': 2, 'wwWeight': 30.0, 'ptWeight': 50.0, 'qaWeight': 20.0},
    ];

    test('should update grading config successfully', () async {
      when(() => mockRepository.updateGradingConfig(
        classId: any(named: 'classId'),
        configs: any(named: 'configs'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(classId: tClassId, configs: tConfigs);

      expect(result.isRight(), true);
      verify(() => mockRepository.updateGradingConfig(
        classId: tClassId,
        configs: tConfigs,
      )).called(1);
    });

    test('should return ValidationFailure when weights do not add up to 100', () async {
      final invalidConfigs = [
        {'gradingPeriodNumber': 1, 'wwWeight': 40.0, 'ptWeight': 40.0, 'qaWeight': 30.0},
      ];

      when(() => mockRepository.updateGradingConfig(
        classId: any(named: 'classId'),
        configs: any(named: 'configs'),
      )).thenAnswer((_) async => Left(ValidationFailure('Weights must add up to 100')));

      final result = await useCase(classId: tClassId, configs: invalidConfigs);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.updateGradingConfig(
        classId: any(named: 'classId'),
        configs: any(named: 'configs'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(classId: tClassId, configs: tConfigs);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.updateGradingConfig(
        classId: any(named: 'classId'),
        configs: any(named: 'configs'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(classId: tClassId, configs: tConfigs);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
