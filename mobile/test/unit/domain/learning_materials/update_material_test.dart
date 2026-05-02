import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/usecases/update_material.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class MockLearningMaterialRepository extends Mock implements LearningMaterialRepository {}

void main() {
  late UpdateMaterial useCase;
  late MockLearningMaterialRepository mockRepository;

  setUp(() {
    mockRepository = MockLearningMaterialRepository();
    useCase = UpdateMaterial(mockRepository);
  });

  group('UpdateMaterial', () {
    const tMaterialId = 'material-1';
    final tUpdated = LearningMaterial(
      id: tMaterialId,
      classId: 'class-1',
      title: 'Updated Chapter 1',
      orderIndex: 1,
      fileCount: 2,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 15),
    );

    test('should update material successfully', () async {
      when(() => mockRepository.updateMaterial(
        materialId: any(named: 'materialId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        contentText: any(named: 'contentText'),
      )).thenAnswer((_) async => Right(tUpdated));

      final result = await useCase(materialId: tMaterialId, title: 'Updated Chapter 1');

      expect(result, Right(tUpdated));
    });

    test('should return ValidationFailure when title is empty', () async {
      when(() => mockRepository.updateMaterial(
        materialId: any(named: 'materialId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        contentText: any(named: 'contentText'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Title cannot be empty')));

      final result = await useCase(materialId: tMaterialId, title: '');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.updateMaterial(
        materialId: any(named: 'materialId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        contentText: any(named: 'contentText'),
      )).thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(materialId: tMaterialId, title: 'New Title');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.updateMaterial(
        materialId: any(named: 'materialId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        contentText: any(named: 'contentText'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(materialId: tMaterialId, title: 'New Title');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
