import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/usecases/create_material.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class MockLearningMaterialRepository extends Mock implements LearningMaterialRepository {}

void main() {
  late CreateMaterial useCase;
  late MockLearningMaterialRepository mockRepository;

  setUp(() {
    mockRepository = MockLearningMaterialRepository();
    useCase = CreateMaterial(mockRepository);
  });

  group('CreateMaterial', () {
    const tClassId = 'class-1';
    const tTitle = 'Chapter 1';
    final tMaterial = LearningMaterial(
      id: 'material-new',
      classId: tClassId,
      title: tTitle,
      orderIndex: 1,
      fileCount: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should create material successfully', () async {
      when(() => mockRepository.createMaterial(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        contentText: any(named: 'contentText'),
      )).thenAnswer((_) async => Right(tMaterial));

      final result = await useCase(classId: tClassId, title: tTitle);

      expect(result, Right(tMaterial));
      expect(result.getOrElse(() => throw Exception()).title, tTitle);
      verify(() => mockRepository.createMaterial(
        classId: tClassId,
        title: tTitle,
        description: null,
        contentText: null,
      )).called(1);
    });

    test('should return ValidationFailure when title is empty', () async {
      when(() => mockRepository.createMaterial(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        contentText: any(named: 'contentText'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Title cannot be empty')));

      final result = await useCase(classId: tClassId, title: '');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.createMaterial(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        contentText: any(named: 'contentText'),
      )).thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(classId: tClassId, title: tTitle);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.createMaterial(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        contentText: any(named: 'contentText'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(classId: tClassId, title: tTitle);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
