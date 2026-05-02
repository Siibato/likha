import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/usecases/search_students.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late SearchStudents useCase;
  late MockClassRepository mockRepository;

  setUp(() {
    mockRepository = MockClassRepository();
    useCase = SearchStudents(mockRepository);
  });

  group('SearchStudents', () {
    final tStudents = <User>[
      User(
        id: 'student-1',
        username: 'john_doe',
        fullName: 'John Doe',
        role: 'student',
        accountStatus: 'activated',
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    test('should search students successfully', () async {
      when(() => mockRepository.searchStudents(query: any(named: 'query')))
          .thenAnswer((_) async => Right(tStudents));

      final result = await useCase(query: 'john');

      expect(result, Right<Failure, List<User>>(tStudents));
      verify(() => mockRepository.searchStudents(query: 'john')).called(1);
    });

    test('should return all students when query is null', () async {
      when(() => mockRepository.searchStudents(query: any(named: 'query')))
          .thenAnswer((_) async => Right<Failure, List<User>>(tStudents));

      final result = await useCase();

      expect(result.isRight(), true);
      verify(() => mockRepository.searchStudents(query: null)).called(1);
    });

    test('should return empty list when no match', () async {
      when(() => mockRepository.searchStudents(query: any(named: 'query')))
          .thenAnswer((_) async => const Right(<User>[]));

      final result = await useCase(query: 'zzznomatch');

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.searchStudents(query: any(named: 'query')))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(query: 'john');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
