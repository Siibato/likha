import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/tos/usecases/delete_competency.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class MockTosRepository extends Mock implements TosRepository {}

void main() {
  late DeleteCompetency useCase;
  late MockTosRepository mockRepository;

  setUp(() {
    mockRepository = MockTosRepository();
    useCase = DeleteCompetency(mockRepository);
  });

  group('DeleteCompetency', () {
    const tCompetencyId = 'comp-1';

    test('should delete competency successfully', () async {
      when(() => mockRepository.deleteCompetency(competencyId: any(named: 'competencyId')))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(tCompetencyId);

      expect(result.isRight(), true);
      verify(() => mockRepository.deleteCompetency(competencyId: tCompetencyId)).called(1);
    });

    test('should return ServerFailure when competency not found', () async {
      when(() => mockRepository.deleteCompetency(competencyId: any(named: 'competencyId')))
          .thenAnswer((_) async => Left(ServerFailure('Competency not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.deleteCompetency(competencyId: any(named: 'competencyId')))
          .thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tCompetencyId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.deleteCompetency(competencyId: any(named: 'competencyId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tCompetencyId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
