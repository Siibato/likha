import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/domain/learning_materials/usecases/upload_file.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class MockLearningMaterialRepository extends Mock implements LearningMaterialRepository {}

void main() {
  late UploadFile useCase;
  late MockLearningMaterialRepository mockRepository;

  setUp(() {
    mockRepository = MockLearningMaterialRepository();
    useCase = UploadFile(mockRepository);
  });

  group('UploadFile', () {
    const tMaterialId = 'material-1';
    const tFilePath = '/tmp/test.pdf';
    const tFileName = 'test.pdf';
    final tFile = MaterialFile(
      id: 'file-new',
      fileName: tFileName,
      fileType: 'application/pdf',
      fileSize: 1024,
      uploadedAt: DateTime(2024, 1, 1),
    );

    test('should upload file successfully', () async {
      when(() => mockRepository.uploadFile(
        materialId: any(named: 'materialId'),
        filePath: any(named: 'filePath'),
        fileName: any(named: 'fileName'),
        onSendProgress: any(named: 'onSendProgress'),
      )).thenAnswer((_) async => Right(tFile));

      final result = await useCase(
        materialId: tMaterialId,
        filePath: tFilePath,
        fileName: tFileName,
      );

      expect(result, Right(tFile));
      expect(result.getOrElse(() => throw Exception()).fileName, tFileName);
      verify(() => mockRepository.uploadFile(
        materialId: tMaterialId,
        filePath: tFilePath,
        fileName: tFileName,
        onSendProgress: null,
      )).called(1);
    });

    test('should return ServerFailure when material not found', () async {
      when(() => mockRepository.uploadFile(
        materialId: any(named: 'materialId'),
        filePath: any(named: 'filePath'),
        fileName: any(named: 'fileName'),
        onSendProgress: any(named: 'onSendProgress'),
      )).thenAnswer((_) async => const Left(ServerFailure('Material not found')));

      final result = await useCase(
        materialId: 'nonexistent-id',
        filePath: tFilePath,
        fileName: tFileName,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.uploadFile(
        materialId: any(named: 'materialId'),
        filePath: any(named: 'filePath'),
        fileName: any(named: 'fileName'),
        onSendProgress: any(named: 'onSendProgress'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(
        materialId: tMaterialId,
        filePath: tFilePath,
        fileName: tFileName,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
