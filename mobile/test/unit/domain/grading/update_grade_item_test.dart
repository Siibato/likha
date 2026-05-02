import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/update_grade_item.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late UpdateGradeItem useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = UpdateGradeItem(mockRepository);
  });

  group('UpdateGradeItem', () {
    const tId = 'item-1';
    final tData = {'title': 'Updated Quiz', 'totalPoints': 80.0};

    test('should update grade item successfully', () async {
      when(() => mockRepository.updateGradeItem(
        id: any(named: 'id'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(id: tId, data: tData);

      expect(result.isRight(), true);
      verify(() => mockRepository.updateGradeItem(id: tId, data: tData)).called(1);
    });

    test('should return ValidationFailure when title is empty', () async {
      when(() => mockRepository.updateGradeItem(
        id: any(named: 'id'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => const Left(ValidationFailure('Title cannot be empty')));

      final result = await useCase(id: tId, data: {'title': ''});

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.updateGradeItem(
        id: any(named: 'id'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(id: tId, data: tData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.updateGradeItem(
        id: any(named: 'id'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(id: tId, data: tData);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
