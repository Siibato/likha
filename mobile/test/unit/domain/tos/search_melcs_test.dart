import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'package:likha/domain/tos/usecases/search_melcs.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class MockTosRepository extends Mock implements TosRepository {}

void main() {
  late SearchMelcs useCase;
  late MockTosRepository mockRepository;

  setUp(() {
    mockRepository = MockTosRepository();
    useCase = SearchMelcs(mockRepository);
  });

  group('SearchMelcs', () {
    final tParams = SearchMelcsParams(subject: 'Math', gradeLevel: 'Grade 7', quarter: 1);
    final tMelcs = [
      const MelcEntryModel(
        id: 1,
        subject: 'Math',
        gradeLevel: 'Grade 7',
        quarter: 1,
        competencyCode: 'M7NS-Ia-1',
        competencyText: 'Describes well-defined sets',
      ),
    ];

    test('should search MELCs successfully', () async {
      when(() => mockRepository.searchMelcs(
        subject: any(named: 'subject'),
        gradeLevel: any(named: 'gradeLevel'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        query: any(named: 'query'),
      )).thenAnswer((_) async => Right(tMelcs));

      final result = await useCase(tParams);

      expect(result, Right(tMelcs));
      verify(() => mockRepository.searchMelcs(
        subject: 'Math',
        gradeLevel: 'Grade 7',
        gradingPeriodNumber: 1,
        query: null,
      )).called(1);
    });

    test('should return empty list when no match', () async {
      when(() => mockRepository.searchMelcs(
        subject: any(named: 'subject'),
        gradeLevel: any(named: 'gradeLevel'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        query: any(named: 'query'),
      )).thenAnswer((_) async => const Right(<MelcEntryModel>[]));

      final result = await useCase(SearchMelcsParams(query: 'zzznomatch'));

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.searchMelcs(
        subject: any(named: 'subject'),
        gradeLevel: any(named: 'gradeLevel'),
        gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        query: any(named: 'query'),
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
