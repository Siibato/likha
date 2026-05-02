import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/learning_materials/usecases/download_file.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class MockLearningMaterialRepository extends Mock implements LearningMaterialRepository {}

void main() {
  late DownloadFile useCase;
  late MockLearningMaterialRepository mockRepository;

  setUp(() {
    mockRepository = MockLearningMaterialRepository();
    useCase = DownloadFile(mockRepository);
  });

  group('DownloadFile', () {
    const tFileId = 'file-1';
    final tBytes = [0x25, 0x50, 0x44, 0x46];

    test('should download file successfully', () async {
      when(() => mockRepository.downloadFile(fileId: any(named: 'fileId')))
          .thenAnswer((_) async => Right(tBytes));

      final result = await useCase(tFileId);

      expect(result, Right(tBytes));
      expect(result.getOrElse(() => []).isNotEmpty, true);
      verify(() => mockRepository.downloadFile(fileId: tFileId)).called(1);
    });

    test('should return ServerFailure when file not found', () async {
      when(() => mockRepository.downloadFile(fileId: any(named: 'fileId')))
          .thenAnswer((_) async => const Left(ServerFailure('File not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return NetworkFailure when offline', () async {
      when(() => mockRepository.downloadFile(fileId: any(named: 'fileId')))
          .thenAnswer((_) async => const Left(NetworkFailure('No internet connection')));

      final result = await useCase(tFileId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.downloadFile(fileId: any(named: 'fileId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tFileId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
