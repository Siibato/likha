import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/usecases/add_competency.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class MockTosRepository extends Mock implements TosRepository {}

void main() {
  late AddCompetency useCase;
  late MockTosRepository mockRepository;

  setUp(() {
    mockRepository = MockTosRepository();
    useCase = AddCompetency(mockRepository);
  });

  group('AddCompetency', () {
    const tTosId = 'tos-1';
    final tData = {'competencyText': 'Understand fractions', 'timeUnitsTaught': 5};
    final tCompetency = TosCompetency(
      id: 'comp-new',
      tosId: tTosId,
      competencyText: 'Understand fractions',
      timeUnitsTaught: 5,
      orderIndex: 1,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should add competency successfully', () async {
      when(() => mockRepository.addCompetency(
        tosId: any(named: 'tosId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Right(tCompetency));

      final result = await useCase(tosId: tTosId, data: tData);

      expect(result, Right(tCompetency));
      verify(() => mockRepository.addCompetency(tosId: tTosId, data: tData)).called(1);
    });

    test('should return ValidationFailure when competency text is empty', () async {
      when(() => mockRepository.addCompetency(
        tosId: any(named: 'tosId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Competency text cannot be empty')));

      final result = await useCase(tosId: tTosId, data: {'competencyText': ''});

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when TOS not found', () async {
      when(() => mockRepository.addCompetency(
        tosId: any(named: 'tosId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => const Left(ServerFailure('TOS not found')));

      final result = await useCase(tosId: 'nonexistent-id', data: tData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.addCompetency(
        tosId: any(named: 'tosId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tosId: tTosId, data: tData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
