import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/usecases/add_student.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late AddStudent useCase;
  late MockClassRepository mockRepository;

  setUp(() {
    mockRepository = MockClassRepository();
    useCase = AddStudent(mockRepository);
  });

  group('AddStudent', () {
    final tParams = AddStudentParams(classId: 'class-1', studentId: 'student-1');
    final tParticipant = Participant(
      id: 'participant-1',
      student: User(
        id: 'student-1',
        username: 'student1',
        fullName: 'Student One',
        role: 'student',
        accountStatus: 'activated',
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      ),
      joinedAt: DateTime(2024, 1, 1),
    );

    test('should add student successfully', () async {
      when(() => mockRepository.addStudent(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => Right(tParticipant));

      final result = await useCase(tParams);

      expect(result, Right(tParticipant));
      verify(() => mockRepository.addStudent(
        classId: 'class-1',
        studentId: 'student-1',
      )).called(1);
    });

    test('should return ValidationFailure when student already in class', () async {
      when(() => mockRepository.addStudent(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
      )).thenAnswer((_) async => Left(ValidationFailure('Student already in class')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.addStudent(
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
      when(() => mockRepository.addStudent(
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
