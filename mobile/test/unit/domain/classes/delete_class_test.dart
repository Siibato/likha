import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/classes/usecases/delete_class.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late DeleteClass useCase;
  late MockClassRepository mockRepository;

  setUp(() {
    mockRepository = MockClassRepository();
    useCase = DeleteClass(mockRepository);
  });

  group('DeleteClass', () {
    const tClassId = 'class-1';

    test('should delete class successfully', () async {
      when(() => mockRepository.deleteClass(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(classId: tClassId);

      expect(result.isRight(), true);
      verify(() => mockRepository.deleteClass(classId: tClassId)).called(1);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.deleteClass(classId: any(named: 'classId')))
          .thenAnswer((_) async => Left(ServerFailure('Class not found')));

      final result = await useCase(classId: 'nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.deleteClass(classId: any(named: 'classId')))
          .thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(classId: tClassId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.deleteClass(classId: any(named: 'classId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(classId: tClassId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
