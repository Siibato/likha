import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/usecases/create_grade_item.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late CreateGradeItem useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = CreateGradeItem(mockRepository);
  });

  group('CreateGradeItem', () {
    final tClassId = 'class-1';
    final tData = const {
      'title': 'New Quiz',
      'component': 'written_work',
      'gradingPeriodNumber': 1,
      'totalPoints': 50.0,
    };
    final tCreatedItem = GradeItem(
      id: 'item-new',
      classId: tClassId,
      title: 'New Quiz',
      component: 'written_work',
      gradingPeriodNumber: 1,
      totalPoints: 50.0,
      sourceType: 'manual',
      orderIndex: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should create grade item successfully', () async {
      when(() => mockRepository.createGradeItem(
        classId: any(named: 'classId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Right(tCreatedItem));

      final result = await useCase(classId: tClassId, data: tData);

      expect(result, Right(tCreatedItem));
      expect(result.getOrElse(() => throw Exception()).title, 'New Quiz');
      verify(() => mockRepository.createGradeItem(
        classId: tClassId,
        data: tData,
      )).called(1);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.createGradeItem(
        classId: any(named: 'classId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Left(ServerFailure('Class not found')));

      final result = await useCase(classId: 'nonexistent-id', data: tData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ValidationFailure when invalid data', () async {
      final invalidData = {
        'title': '',
        'component': 'written_work',
      };

      when(() => mockRepository.createGradeItem(
        classId: any(named: 'classId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Left(ValidationFailure('Title cannot be empty')));

      final result = await useCase(classId: tClassId, data: invalidData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.createGradeItem(
        classId: any(named: 'classId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(classId: tClassId, data: tData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.createGradeItem(
        classId: any(named: 'classId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(classId: tClassId, data: tData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
