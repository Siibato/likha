import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/setup_grading.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late SetupGrading useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = SetupGrading(mockRepository);
  });

  group('SetupGrading', () {
    final tParams = SetupGradingParams(
      classId: 'class-1',
      gradeLevel: 'Grade 7',
      subjectGroup: 'Science',
      schoolYear: '2024-2025',
      semester: 1,
    );

    test('should setup grading successfully', () async {
      when(() => mockRepository.setupGrading(
        classId: any(named: 'classId'),
        gradeLevel: any(named: 'gradeLevel'),
        subjectGroup: any(named: 'subjectGroup'),
        schoolYear: any(named: 'schoolYear'),
        semester: any(named: 'semester'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(tParams);

      expect(result.isRight(), true);
      verify(() => mockRepository.setupGrading(
        classId: 'class-1',
        gradeLevel: 'Grade 7',
        subjectGroup: 'Science',
        schoolYear: '2024-2025',
        semester: 1,
      )).called(1);
    });

    test('should return ServerFailure when class not found', () async {
      final params = SetupGradingParams(
        classId: 'nonexistent-id',
        gradeLevel: 'Grade 7',
        subjectGroup: 'Science',
        schoolYear: '2024-2025',
      );

      when(() => mockRepository.setupGrading(
        classId: any(named: 'classId'),
        gradeLevel: any(named: 'gradeLevel'),
        subjectGroup: any(named: 'subjectGroup'),
        schoolYear: any(named: 'schoolYear'),
        semester: any(named: 'semester'),
      )).thenAnswer((_) async => Left(ServerFailure('Class not found')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when invalid grade level', () async {
      final params = SetupGradingParams(
        classId: 'class-1',
        gradeLevel: 'Invalid Level',
        subjectGroup: 'Science',
        schoolYear: '2024-2025',
      );

      when(() => mockRepository.setupGrading(
        classId: any(named: 'classId'),
        gradeLevel: any(named: 'gradeLevel'),
        subjectGroup: any(named: 'subjectGroup'),
        schoolYear: any(named: 'schoolYear'),
        semester: any(named: 'semester'),
      )).thenAnswer((_) async => Left(ValidationFailure('Invalid grade level')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.setupGrading(
        classId: any(named: 'classId'),
        gradeLevel: any(named: 'gradeLevel'),
        subjectGroup: any(named: 'subjectGroup'),
        schoolYear: any(named: 'schoolYear'),
        semester: any(named: 'semester'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.setupGrading(
        classId: any(named: 'classId'),
        gradeLevel: any(named: 'gradeLevel'),
        subjectGroup: any(named: 'subjectGroup'),
        schoolYear: any(named: 'schoolYear'),
        semester: any(named: 'semester'),
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
