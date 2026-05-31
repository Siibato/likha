import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/usecases/get_class_detail.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late GetClassDetail useCase;
  late MockClassRepository mockRepository;

  setUp(() {
    mockRepository = MockClassRepository();
    useCase = GetClassDetail(mockRepository);
  });

  group('GetClassDetail', () {
    const tClassId = 'class-1';
    final tClassDetail = ClassDetail(
      id: tClassId,
      title: 'Science 7',
      teacherId: 'teacher-1',
      isArchived: false,
      students: const [],
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should get class detail successfully', () async {
      when(() => mockRepository.getClassDetail(classId: any(named: 'classId')))
          .thenAnswer((_) async => Right(tClassDetail));

      final result = await useCase(tClassId);

      expect(result, Right(tClassDetail));
      expect(result.getOrElse(() => throw Exception()).id, tClassId);
      verify(() => mockRepository.getClassDetail(classId: tClassId)).called(1);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.getClassDetail(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Left(ServerFailure('Class not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getClassDetail(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tClassId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
