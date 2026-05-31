import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/usecases/get_tos_list.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class MockTosRepository extends Mock implements TosRepository {}

void main() {
  late GetTosList useCase;
  late MockTosRepository mockRepository;

  setUp(() {
    mockRepository = MockTosRepository();
    useCase = GetTosList(mockRepository);
  });

  group('GetTosList', () {
    const tClassId = 'class-1';
    final tTosList = [
      TableOfSpecifications(
        id: 'tos-1',
        classId: tClassId,
        gradingPeriodNumber: 1,
        title: 'Q1 TOS',
        classificationMode: 'difficulty',
        totalItems: 50,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

    test('should get TOS list successfully', () async {
      when(() => mockRepository.getTosList(classId: any(named: 'classId')))
          .thenAnswer((_) async => Right(tTosList));

      final result = await useCase(tClassId);

      expect(result, Right(tTosList));
      expect(result.getOrElse(() => []).length, 1);
      verify(() => mockRepository.getTosList(classId: tClassId)).called(1);
    });

    test('should return empty list when no TOS exists', () async {
      when(() => mockRepository.getTosList(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Right(<TableOfSpecifications>[]));

      final result = await useCase(tClassId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.getTosList(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Left(ServerFailure('Class not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getTosList(classId: any(named: 'classId')))
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
