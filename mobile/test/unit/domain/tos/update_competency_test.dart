import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/usecases/update_competency.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class MockTosRepository extends Mock implements TosRepository {}

void main() {
  late UpdateCompetency useCase;
  late MockTosRepository mockRepository;

  setUp(() {
    mockRepository = MockTosRepository();
    useCase = UpdateCompetency(mockRepository);
  });

  group('UpdateCompetency', () {
    const tCompetencyId = 'comp-1';
    final tData = {'competencyText': 'Updated text', 'timeUnitsTaught': 7};
    final tUpdated = TosCompetency(
      id: tCompetencyId,
      tosId: 'tos-1',
      competencyText: 'Updated text',
      timeUnitsTaught: 7,
      orderIndex: 1,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 15),
    );

    test('should update competency successfully', () async {
      when(() => mockRepository.updateCompetency(
        competencyId: any(named: 'competencyId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Right(tUpdated));

      final result = await useCase(competencyId: tCompetencyId, data: tData);

      expect(result, Right(tUpdated));
      verify(() => mockRepository.updateCompetency(competencyId: tCompetencyId, data: tData)).called(1);
    });

    test('should return ServerFailure when competency not found', () async {
      when(() => mockRepository.updateCompetency(
        competencyId: any(named: 'competencyId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Left(ServerFailure('Competency not found')));

      final result = await useCase(competencyId: 'nonexistent-id', data: tData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.updateCompetency(
        competencyId: any(named: 'competencyId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(competencyId: tCompetencyId, data: tData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.updateCompetency(
        competencyId: any(named: 'competencyId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(competencyId: tCompetencyId, data: tData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
