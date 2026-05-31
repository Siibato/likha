import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/usecases/create_class.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late CreateClass useCase;
  late MockClassRepository mockRepository;

  setUp(() {
    mockRepository = MockClassRepository();
    useCase = CreateClass(mockRepository);
  });

  group('CreateClass', () {
    final tParams = CreateClassParams(title: 'Science 7', isAdvisory: false);
    final tClass = ClassEntity(
      id: 'class-new',
      title: 'Science 7',
      teacherId: 'teacher-1',
      teacherUsername: 'teacher1',
      teacherFullName: 'Teacher One',
      isArchived: false,
      studentCount: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should create class successfully', () async {
      when(() => mockRepository.createClass(
        title: any(named: 'title'),
        description: any(named: 'description'),
        teacherId: any(named: 'teacherId'),
        teacherUsername: any(named: 'teacherUsername'),
        teacherFullName: any(named: 'teacherFullName'),
        isAdvisory: any(named: 'isAdvisory'),
      )).thenAnswer((_) async => Right(tClass));

      final result = await useCase(tParams);

      expect(result, Right(tClass));
      expect(result.getOrElse(() => throw Exception()).title, 'Science 7');
      verify(() => mockRepository.createClass(
        title: 'Science 7',
        description: null,
        teacherId: null,
        teacherUsername: null,
        teacherFullName: null,
        isAdvisory: false,
      )).called(1);
    });

    test('should return ValidationFailure when title is empty', () async {
      final invalidParams = CreateClassParams(title: '');

      when(() => mockRepository.createClass(
        title: any(named: 'title'),
        description: any(named: 'description'),
        teacherId: any(named: 'teacherId'),
        teacherUsername: any(named: 'teacherUsername'),
        teacherFullName: any(named: 'teacherFullName'),
        isAdvisory: any(named: 'isAdvisory'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Title cannot be empty')));

      final result = await useCase(invalidParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.createClass(
        title: any(named: 'title'),
        description: any(named: 'description'),
        teacherId: any(named: 'teacherId'),
        teacherUsername: any(named: 'teacherUsername'),
        teacherFullName: any(named: 'teacherFullName'),
        isAdvisory: any(named: 'isAdvisory'),
      )).thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.createClass(
        title: any(named: 'title'),
        description: any(named: 'description'),
        teacherId: any(named: 'teacherId'),
        teacherUsername: any(named: 'teacherUsername'),
        teacherFullName: any(named: 'teacherFullName'),
        isAdvisory: any(named: 'isAdvisory'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
