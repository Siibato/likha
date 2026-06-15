import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/learning_materials/usecases/delete_material.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class MockLearningMaterialRepository extends Mock implements LearningMaterialRepository {}

void main() {
  late DeleteMaterial useCase;
  late MockLearningMaterialRepository mockRepository;

  setUp(() {
    mockRepository = MockLearningMaterialRepository();
    useCase = DeleteMaterial(mockRepository);
  });

  group('DeleteMaterial', () {
    const tMaterialId = 'material-1';

    test('should delete material successfully', () async {
      when(() => mockRepository.deleteMaterial(materialId: any(named: 'materialId')))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(tMaterialId);

      expect(result.isRight(), true);
      verify(() => mockRepository.deleteMaterial(materialId: tMaterialId)).called(1);
    });

    test('should return ServerFailure when material not found', () async {
      when(() => mockRepository.deleteMaterial(materialId: any(named: 'materialId')))
          .thenAnswer((_) async => const Left(ServerFailure('Material not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.deleteMaterial(materialId: any(named: 'materialId')))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tMaterialId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.deleteMaterial(materialId: any(named: 'materialId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tMaterialId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
