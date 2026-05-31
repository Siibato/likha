import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/usecases/update_tos.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class MockTosRepository extends Mock implements TosRepository {}

void main() {
  late UpdateTos useCase;
  late MockTosRepository mockRepository;

  setUp(() {
    mockRepository = MockTosRepository();
    useCase = UpdateTos(mockRepository);
  });

  group('UpdateTos', () {
    const tTosId = 'tos-1';
    final tData = {'title': 'Updated TOS', 'totalItems': 60};
    final tUpdatedTos = TableOfSpecifications(
      id: tTosId,
      classId: 'class-1',
      gradingPeriodNumber: 1,
      title: 'Updated TOS',
      classificationMode: 'difficulty',
      totalItems: 60,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 15),
    );

    test('should update TOS successfully', () async {
      when(() => mockRepository.updateTos(
        tosId: any(named: 'tosId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Right(tUpdatedTos));

      final result = await useCase(tosId: tTosId, data: tData);

      expect(result, Right(tUpdatedTos));
      verify(() => mockRepository.updateTos(tosId: tTosId, data: tData)).called(1);
    });

    test('should return ServerFailure when TOS not found', () async {
      when(() => mockRepository.updateTos(
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

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.updateTos(
        tosId: any(named: 'tosId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tosId: tTosId, data: tData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.updateTos(
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
