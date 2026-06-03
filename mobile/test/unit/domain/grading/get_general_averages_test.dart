import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/grading/entities/general_average.dart';
import 'package:likha/domain/grading/usecases/get_general_averages.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class MockGradingRepository extends Mock implements GradingRepository {}

void main() {
  late GetGeneralAverages useCase;
  late MockGradingRepository mockRepository;

  setUp(() {
    mockRepository = MockGradingRepository();
    useCase = GetGeneralAverages(mockRepository);
  });

  group('GetGeneralAverages', () {
    const tClassId = 'class-1';
    const tResponse = GeneralAverageResponse(
      classId: tClassId,
      students: [],
    );

    test('should get general averages successfully', () async {
      when(() => mockRepository.getGeneralAverages(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Right(tResponse));

      final result = await useCase(tClassId);

      expect(result, const Right(tResponse));
      verify(() => mockRepository.getGeneralAverages(classId: tClassId)).called(1);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.getGeneralAverages(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Left(ServerFailure('Class not found')));

      final result = await useCase('nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getGeneralAverages(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(tClassId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
