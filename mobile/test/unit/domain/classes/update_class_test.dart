import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/usecases/update_class.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late UpdateClass useCase;
  late MockClassRepository mockRepository;

  setUp(() {
    mockRepository = MockClassRepository();
    useCase = UpdateClass(mockRepository);
  });

  group('UpdateClass', () {
    const tClassId = 'class-1';
    final tUpdatedClass = ClassEntity(
      id: tClassId,
      title: 'Updated Science 7',
      teacherId: 'teacher-1',
      teacherUsername: 'teacher1',
      teacherFullName: 'Teacher One',
      isArchived: false,
      studentCount: 30,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 15),
    );

    test('should update class successfully', () async {
      final params = UpdateClassParams(classId: tClassId, title: 'Updated Science 7');

      when(() => mockRepository.updateClass(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        teacherId: any(named: 'teacherId'),
        isAdvisory: any(named: 'isAdvisory'),
      )).thenAnswer((_) async => Right(tUpdatedClass));

      final result = await useCase(params);

      expect(result, Right(tUpdatedClass));
      expect(result.getOrElse(() => throw Exception()).title, 'Updated Science 7');
    });

    test('should return ValidationFailure when title is empty', () async {
      final params = UpdateClassParams(classId: tClassId, title: '');

      when(() => mockRepository.updateClass(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        teacherId: any(named: 'teacherId'),
        isAdvisory: any(named: 'isAdvisory'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Title cannot be empty')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      final params = UpdateClassParams(classId: tClassId, title: 'New Title');

      when(() => mockRepository.updateClass(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        teacherId: any(named: 'teacherId'),
        isAdvisory: any(named: 'isAdvisory'),
      )).thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      final params = UpdateClassParams(classId: tClassId, title: 'New Title');

      when(() => mockRepository.updateClass(
        classId: any(named: 'classId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        teacherId: any(named: 'teacherId'),
        isAdvisory: any(named: 'isAdvisory'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
