import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/usecases/get_grade_items.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late GetGradeItems useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = GetGradeItems(mockRepository);
  });

  group('GetGradeItems', () {
    final tParams = GetGradeItemsParams(
      classId: 'class-1',
      gradingPeriodNumber: 1,
      component: 'written_work',
    );
    final tGradeItems = [
      GradeItem(
        id: 'item-1',
        classId: 'class-1',
        title: 'Quiz 1',
        component: 'written_work',
        gradingPeriodNumber: 1,
        totalPoints: 100.0,
        sourceType: 'manual',
        orderIndex: 0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      GradeItem(
        id: 'item-2',
        classId: 'class-1',
        title: 'Quiz 2',
        component: 'written_work',
        gradingPeriodNumber: 1,
        totalPoints: 100.0,
        sourceType: 'manual',
        orderIndex: 1,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
      ),
    ];

    test('should get grade items successfully', () async {
      when(() => mockRepository.getGradeItems(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
      )).thenAnswer((_) async => Right(tGradeItems));

      final result = await useCase(tParams);

      expect(result, Right(tGradeItems));
      expect(result.getOrElse(() => []).length, 2);
      verify(() => mockRepository.getGradeItems(
        classId: 'class-1',
        gradingPeriodNumber: 1,
        component: 'written_work',
      )).called(1);
    });

    test('should get all grade items without component filter', () async {
      final params = GetGradeItemsParams(
        classId: 'class-1',
        gradingPeriodNumber: 1,
      );

      when(() => mockRepository.getGradeItems(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
      )).thenAnswer((_) async => Right(tGradeItems));

      final result = await useCase(params);

      expect(result.isRight(), true);
      verify(() => mockRepository.getGradeItems(
        classId: 'class-1',
        gradingPeriodNumber: 1,
        component: null,
      )).called(1);
    });

    test('should return ServerFailure when class not found', () async {
      final params = GetGradeItemsParams(
        classId: 'nonexistent-id',
        gradingPeriodNumber: 1,
      );

      when(() => mockRepository.getGradeItems(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
      )).thenAnswer((_) async => const Left(ServerFailure('Class not found')));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getGradeItems(
        classId: any(named: 'classId'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        component: any(named: 'component'),
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
