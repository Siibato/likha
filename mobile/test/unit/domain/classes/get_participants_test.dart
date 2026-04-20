import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/usecases/get_participants.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late GetParticipants useCase;
  late MockClassRepository mockRepository;

  setUp(() {
    mockRepository = MockClassRepository();
    useCase = GetParticipants(mockRepository);
  });

  group('GetParticipants', () {
    const tClassId = 'class-1';
    final tParticipants = <User>[
      User(
        id: 'student-1',
        username: 'student1',
        fullName: 'Student One',
        role: 'student',
        accountStatus: 'activated',
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      ),
      User(
        id: 'student-2',
        username: 'student2',
        fullName: 'Student Two',
        role: 'student',
        accountStatus: 'activated',
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    test('should get participants successfully', () async {
      when(() => mockRepository.getParticipants(classId: any(named: 'classId')))
          .thenAnswer((_) async => Right(tParticipants));

      final result = await useCase(classId: tClassId);

      expect(result, Right(tParticipants));
      expect(result.getOrElse(() => []).length, 2);
      verify(() => mockRepository.getParticipants(classId: tClassId)).called(1);
    });

    test('should return empty list when no participants', () async {
      when(() => mockRepository.getParticipants(classId: any(named: 'classId')))
          .thenAnswer((_) async => const Right(<User>[]));

      final result = await useCase(classId: tClassId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).isEmpty, true);
    });

    test('should return ServerFailure when class not found', () async {
      when(() => mockRepository.getParticipants(classId: any(named: 'classId')))
          .thenAnswer((_) async => Left(ServerFailure('Class not found')));

      final result = await useCase(classId: 'nonexistent-id');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      when(() => mockRepository.getParticipants(classId: any(named: 'classId')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      final result = await useCase(classId: tClassId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('should not be right'),
      );
    });
  });
}
