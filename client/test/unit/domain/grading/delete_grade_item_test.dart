import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/usecases/delete_grade_item.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late DeleteGradeItem useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = DeleteGradeItem(mockRepository);
  });

  group('DeleteGradeItem', () {
    const tId = 'item-1';

    test('should delete grade item successfully', () async {
      when(() => mockRepository.deleteGradeItem(id: any(named: 'id')))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(tId);

      expect(result.isRight(), true);
      verify(() => mockRepository.deleteGradeItem(id: tId)).called(1);
    });

    test('should return ServerFailure when item not found', () async {
      when(() => mockRepository.deleteGradeItem(id: any(named: 'id')))
          .thenAnswer((_) async => const Left(ServerFailure('Grade item not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.deleteGradeItem(id: any(named: 'id')))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Unauthorized')));

      final result = await useCase(tId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.deleteGradeItem(id: any(named: 'id')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
