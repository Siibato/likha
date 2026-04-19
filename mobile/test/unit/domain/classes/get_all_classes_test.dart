import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/usecases/get_all_classes.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late GetAllClasses useCase;
  late MockClassRepository mockRepository;

  setUp(() {
    mockRepository = MockClassRepository();
    useCase = GetAllClasses(mockRepository);
  });

  group('GetAllClasses', () {
    final tClasses = [
      ClassEntity(
        id: 'class-1',
        title: 'Science 7',
        teacherId: 'teacher-1',
        teacherUsername: 'teacher1',
        teacherFullName: 'Teacher One',
        isArchived: false,
        studentCount: 30,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

    test('should get all classes successfully', () async {
      when(() => mockRepository.getAllClasses(skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
          .thenAnswer((_) async => Right(tClasses));

      final result = await useCase();

      expect(result, Right(tClasses));
      verify(() => mockRepository.getAllClasses(skipBackgroundRefresh: false)).called(1);
    });

    test('should return empty list when no classes exist', () async {
      when(() => mockRepository.getAllClasses(skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
          .thenAnswer((_) async => const Right(<ClassEntity>[]));

      final result = await useCase();

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return NetworkFailure when offline', () async {
      when(() => mockRepository.getAllClasses(skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
          .thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      final result = await useCase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getAllClasses(skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
