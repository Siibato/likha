import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/usecases/get_tos_detail.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class MockTosRepository extends Mock implements TosRepository {}

void main() {
  late GetTosDetail useCase;
  late MockTosRepository mockRepository;

  setUp(() {
    mockRepository = MockTosRepository();
    useCase = GetTosDetail(mockRepository);
  });

  group('GetTosDetail', () {
    const tTosId = 'tos-1';
    final tTos = TableOfSpecifications(
      id: tTosId,
      classId: 'class-1',
      gradingPeriodNumber: 1,
      title: 'Q1 TOS',
      classificationMode: 'difficulty',
      totalItems: 50,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
    final tCompetency = TosCompetency(
      id: 'comp-1',
      tosId: tTosId,
      competencyText: 'Understand fractions',
      timeUnitsTaught: 5,
      orderIndex: 1,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should get TOS detail successfully', () async {
      when(() => mockRepository.getTosDetail(tosId: any(named: 'tosId')))
          .thenAnswer((_) async => Right((tTos, [tCompetency])));

      final result = await useCase(tTosId);

      expect(result.isRight(), true);
      final (tos, competencies) = result.getOrElse(() => throw Exception());
      expect(tos.id, tTosId);
      expect(competencies.length, 1);
      verify(() => mockRepository.getTosDetail(tosId: tTosId)).called(1);
    });

    test('should return ServerFailure when TOS not found', () async {
      when(() => mockRepository.getTosDetail(tosId: any(named: 'tosId')))
          .thenAnswer((_) async => const Left(ServerFailure('TOS not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getTosDetail(tosId: any(named: 'tosId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tTosId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
