import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/usecases/create_tos.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class MockTosRepository extends Mock implements TosRepository {}

void main() {
  late CreateTos useCase;
  late MockTosRepository mockRepository;

  setUp(() {
    mockRepository = MockTosRepository();
    useCase = CreateTos(mockRepository);
  });

  group('CreateTos', () {
    const tClassId = 'class-1';
    final tData = {'title': 'Q1 TOS', 'gradingPeriodNumber': 1, 'totalItems': 50, 'classificationMode': 'difficulty'};
    final tTos = TableOfSpecifications(
      id: 'tos-new',
      classId: tClassId,
      gradingPeriodNumber: 1,
      title: 'Q1 TOS',
      classificationMode: 'difficulty',
      totalItems: 50,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should create TOS successfully', () async {
      when(() => mockRepository.createTos(
        classId: any(named: 'classId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Right(tTos));

      final result = await useCase(classId: tClassId, data: tData);

      expect(result, Right(tTos));
      expect(result.getOrElse(() => throw Exception()).classId, tClassId);
      verify(() => mockRepository.createTos(classId: tClassId, data: tData)).called(1);
    });

    test('should return ValidationFailure when title is empty', () async {
      when(() => mockRepository.createTos(
        classId: any(named: 'classId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Left(ValidationFailure('Title cannot be empty')));

      final result = await useCase(classId: tClassId, data: {'title': ''});

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return UnauthorizedFailure when not authorized', () async {
      when(() => mockRepository.createTos(
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
      when(() => mockRepository.createTos(
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
