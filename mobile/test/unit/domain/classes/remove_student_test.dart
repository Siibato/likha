import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/classes/usecases/remove_student.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late RemoveStudent useCase;
  late MockClassRepository mockRepository;

  setUp(() {
    mockRepository = MockClassRepository();
    useCase = RemoveStudent(mockRepository);
  });

  group('RemoveStudent', () {
    final tParams = RemoveStudentParams(classId: 'class-1', studentId: 'student-1');

    test('should remove student successfully', () async {
      when(() => mockRepository.removeStudent(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(tParams);

      expect(result.isRight(), true);
      verify(() => mockRepository.removeStudent(
        classId: 'class-1',
        studentId: 'student-1',
      )).called(1);
    });

    test('should return ServerFailure when student not in class', () async {
      when(() => mockRepository.removeStudent(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => Left(ServerFailure('Student not found in class')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.removeStudent(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.removeStudent(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
