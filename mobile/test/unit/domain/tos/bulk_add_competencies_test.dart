import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/usecases/bulk_add_competencies.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class MockTosRepository extends Mock implements TosRepository {}

void main() {
  late BulkAddCompetencies useCase;
  late MockTosRepository mockRepository;

  setUp(() {
    mockRepository = MockTosRepository();
    useCase = BulkAddCompetencies(mockRepository);
  });

  group('BulkAddCompetencies', () {
    const tTosId = 'tos-1';
    final tCompetenciesData = [
      {'competencyText': 'Competency 1', 'timeUnitsTaught': 5},
      {'competencyText': 'Competency 2', 'timeUnitsTaught': 3},
    ];
    final tCreated = [
      TosCompetency(
        id: 'comp-1',
        tosId: tTosId,
        competencyText: 'Competency 1',
        timeUnitsTaught: 5,
        orderIndex: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      TosCompetency(
        id: 'comp-2',
        tosId: tTosId,
        competencyText: 'Competency 2',
        timeUnitsTaught: 3,
        orderIndex: 2,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

    test('should bulk add competencies successfully', () async {
      when(() => mockRepository.bulkAddCompetencies(
        tosId: any(named: 'tosId'),
        competencies: any(named: 'competencies'),
      )).thenAnswer((_) async => Right(tCreated));

      final result = await useCase(tosId: tTosId, competencies: tCompetenciesData);

      expect(result, Right(tCreated));
      expect(result.getOrElse(() => []).length, 2);
      verify(() => mockRepository.bulkAddCompetencies(
        tosId: tTosId,
        competencies: tCompetenciesData,
      )).called(1);
    });

    test('should return ValidationFailure when list is empty', () async {
      when(() => mockRepository.bulkAddCompetencies(
        tosId: any(named: 'tosId'),
        competencies: any(named: 'competencies'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Competencies list cannot be empty')));

      final result = await useCase(tosId: tTosId, competencies: []);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.bulkAddCompetencies(
        tosId: any(named: 'tosId'),
        competencies: any(named: 'competencies'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tosId: tTosId, competencies: tCompetenciesData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
