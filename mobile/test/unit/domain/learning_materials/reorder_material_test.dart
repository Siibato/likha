import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/usecases/reorder_material.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class MockLearningMaterialRepository extends Mock implements LearningMaterialRepository {}

void main() {
  late ReorderMaterial useCase;
  late ReorderAllMaterials reorderAllUseCase;
  late MockLearningMaterialRepository mockRepository;

  setUp(() {
    mockRepository = MockLearningMaterialRepository();
    useCase = ReorderMaterial(mockRepository);
    reorderAllUseCase = ReorderAllMaterials(mockRepository);
  });

  group('ReorderMaterial', () {
    const tMaterialId = 'material-1';
    final tReordered = LearningMaterial(
      id: tMaterialId,
      classId: 'class-1',
      title: 'Chapter 1',
      orderIndex: 3,
      fileCount: 2,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 15),
    );

    test('should reorder material successfully', () async {
      when(() => mockRepository.reorderMaterial(
        materialId: any(named: 'materialId'),
        newOrderIndex: any(named: 'newOrderIndex'),
      )).thenAnswer((_) async => Right(tReordered));

      final result = await useCase(materialId: tMaterialId, newOrderIndex: 3);

      expect(result, Right(tReordered));
      expect(result.getOrElse(() => throw Exception()).orderIndex, 3);
      verify(() => mockRepository.reorderMaterial(
        materialId: tMaterialId,
        newOrderIndex: 3,
      )).called(1);
    });

    test('should return ServerFailure when material not found', () async {
      when(() => mockRepository.reorderMaterial(
        materialId: any(named: 'materialId'),
        newOrderIndex: any(named: 'newOrderIndex'),
      )).thenAnswer((_) async => Left(ServerFailure('Material not found')));

      final result = await useCase(materialId: 'nonexistent-id', newOrderIndex: 3);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.reorderMaterial(
        materialId: any(named: 'materialId'),
        newOrderIndex: any(named: 'newOrderIndex'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(materialId: tMaterialId, newOrderIndex: 3);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });

  group('ReorderAllMaterials', () {
    const tClassId = 'class-1';
    final tMaterialIds = ['material-3', 'material-1', 'material-2'];

    test('should reorder all materials successfully', () async {
      when(() => mockRepository.reorderAllMaterials(
        classId: any(named: 'classId'),
        materialIds: any(named: 'materialIds'),
      )).thenAnswer((_) async => const Right(null));

      final result = await reorderAllUseCase(classId: tClassId, materialIds: tMaterialIds);

      expect(result.isRight(), true);
      verify(() => mockRepository.reorderAllMaterials(
        classId: tClassId,
        materialIds: tMaterialIds,
      )).called(1);
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.reorderAllMaterials(
        classId: any(named: 'classId'),
        materialIds: any(named: 'materialIds'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await reorderAllUseCase(classId: tClassId, materialIds: tMaterialIds);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
