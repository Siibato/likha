import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/usecases/get_material_detail.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class MockLearningMaterialRepository extends Mock implements LearningMaterialRepository {}

void main() {
  late GetMaterialDetail useCase;
  late MockLearningMaterialRepository mockRepository;

  setUp(() {
    mockRepository = MockLearningMaterialRepository();
    useCase = GetMaterialDetail(mockRepository);
  });

  group('GetMaterialDetail', () {
    const tMaterialId = 'material-1';
    final tDetail = MaterialDetail(
      id: tMaterialId,
      classId: 'class-1',
      title: 'Chapter 1',
      orderIndex: 1,
      files: [],
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should get material detail successfully', () async {
      when(() => mockRepository.getMaterialDetail(materialId: any(named: 'materialId')))
          .thenAnswer((_) async => Right(tDetail));

      final result = await useCase(tMaterialId);

      expect(result, Right(tDetail));
      expect(result.getOrElse(() => throw Exception()).id, tMaterialId);
      verify(() => mockRepository.getMaterialDetail(materialId: tMaterialId)).called(1);
    });

    test('should return ServerFailure when material not found', () async {
      when(() => mockRepository.getMaterialDetail(materialId: any(named: 'materialId')))
          .thenAnswer((_) async => Left(ServerFailure('Material not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getMaterialDetail(materialId: any(named: 'materialId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tMaterialId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
