import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/usecases/get_materials.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class MockLearningMaterialRepository extends Mock implements LearningMaterialRepository {}

void main() {
  late GetMaterials useCase;
  late MockLearningMaterialRepository mockRepository;

  setUp(() {
    mockRepository = MockLearningMaterialRepository();
    useCase = GetMaterials(mockRepository);
  });

  group('GetMaterials', () {
    const tClassId = 'class-1';
    final tMaterials = [
      LearningMaterial(
        id: 'material-1',
        classId: tClassId,
        title: 'Chapter 1',
        orderIndex: 1,
        fileCount: 2,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

    test('should get materials successfully', () async {
      when(() => mockRepository.getMaterials(classId: any(named: 'classId')))
          .thenAnswer((_) async => Right(tMaterials));

      final result = await useCase(tClassId);

      expect(result, Right(tMaterials));
      verify(() => mockRepository.getMaterials(classId: tClassId)).called(1);
    });

    test('should return empty list when no materials', () async {
      when(() => mockRepository.getMaterials(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Right(<LearningMaterial>[]));

      final result = await useCase(tClassId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.getMaterials(classId: any(named: 'classId')))
          .thenAnswer((_) async => Left(ServerFailure('Class not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return NetworkFailure when offline', () async {
      when(() => mockRepository.getMaterials(classId: any(named: 'classId')))
          .thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      final result = await useCase(tClassId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
