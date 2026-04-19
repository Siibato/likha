import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/learning_materials/usecases/delete_file.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class MockLearningMaterialRepository extends Mock implements LearningMaterialRepository {}

void main() {
  late DeleteFile useCase;
  late MockLearningMaterialRepository mockRepository;

  setUp(() {
    mockRepository = MockLearningMaterialRepository();
    useCase = DeleteFile(mockRepository);
  });

  group('DeleteFile', () {
    const tFileId = 'file-1';

    test('should delete file successfully', () async {
      when(() => mockRepository.deleteFile(fileId: any(named: 'fileId')))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(tFileId);

      expect(result.isRight(), true);
      verify(() => mockRepository.deleteFile(fileId: tFileId)).called(1);
    });

    test('should return ServerFailure when file not found', () async {
      when(() => mockRepository.deleteFile(fileId: any(named: 'fileId')))
          .thenAnswer((_) async => Left(ServerFailure('File not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.deleteFile(fileId: any(named: 'fileId')))
          .thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tFileId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.deleteFile(fileId: any(named: 'fileId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tFileId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
