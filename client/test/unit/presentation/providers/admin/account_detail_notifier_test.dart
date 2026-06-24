import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/data/models/auth/account_detail_response_model.dart';
import 'package:likha/data/models/auth/teacher_details_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/student_records/learner_details_model.dart';
import 'package:likha/domain/auth/usecases/get_account_details.dart';
import 'package:likha/domain/auth/usecases/upsert_account_details.dart';
import 'package:likha/presentation/providers/admin/account_detail_provider.dart';

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGetAccountDetails extends Mock implements GetAccountDetails {}
class MockUpsertAccountDetails extends Mock implements UpsertAccountDetails {}

AccountDetailNotifier _buildNotifier({
  Ref? ref,
  MockGetAccountDetails? getAccountDetails,
  MockUpsertAccountDetails? upsertAccountDetails,
}) {
  return AccountDetailNotifier(
    ref ?? _FakeRef(),
    getAccountDetails ?? MockGetAccountDetails(),
    upsertAccountDetails ?? MockUpsertAccountDetails(),
  );
}

AccountDetailResponseModel _fakeResponse({
  LearnerDetailsModel? learner,
  TeacherDetailsModel? teacher,
}) {
  return AccountDetailResponseModel(
    user: UserModel(
      id: 'user-1',
      username: 'testuser',
      firstName: 'Test',
      lastName: 'User',
      role: 'student',
      accountStatus: 'activated',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
    ),
    learnerDetails: learner,
    teacherDetails: teacher,
  );
}

void main() {
  const tFailure = ServerFailure('Server error');
  const tUserId = 'user-1';

  const tLearner = LearnerDetailsModel(
    id: 'ld-1',
    userId: tUserId,
    lrn: '123456',
    sex: 'Male',
    birthdate: '2000-01-01',
    birthplace: 'City',
    homeAddress: 'Address',
    fatherName: 'Father',
    fatherContact: '123',
    motherName: 'Mother',
    motherContact: '456',
    guardianName: 'Guardian',
    guardianContact: '789',
    trackStrand: 'STEM',
    curriculum: 'K-12',
    dateAdmitted: '2020-01-01',
  );

  const tTeacher = TeacherDetailsModel(
    id: 'td-1',
    userId: tUserId,
    licenseId: 'lic-1',
    rank: 'Teacher I',
    position: 'Teacher',
    sex: 'Female',
    birthdate: '1990-01-01',
    homeAddress: 'Address',
    dateHired: '2020-01-01',
    educationLevel: 'Masteral',
    specialization: 'Math',
    contactNumber: '123456',
  );

  setUpAll(() {
    registerFallbackValue(UpsertAccountDetailsParams(
      userId: 'fallback',
    ));
  });

  group('AccountDetailNotifier', () {
    group('loadAccountDetails', () {
      test('should update state with details on success', () async {
        final getAccountDetails = MockGetAccountDetails();
        final response = _fakeResponse(learner: tLearner);
        when(() => getAccountDetails(tUserId)).thenAnswer(
          (_) async => Right(response),
        );
        final notifier = _buildNotifier(getAccountDetails: getAccountDetails);

        await notifier.loadAccountDetails(tUserId);

        expect(notifier.state.isLoading, false);
        expect(notifier.state.learnerDetails, isNotNull);
        expect(notifier.state.learnerDetails?.lrn, '123456');
        expect(notifier.state.error, isNull);
      });

      test('should update state with error on failure', () async {
        final getAccountDetails = MockGetAccountDetails();
        when(() => getAccountDetails(tUserId)).thenAnswer(
          (_) async => const Left(tFailure),
        );
        final notifier = _buildNotifier(getAccountDetails: getAccountDetails);

        await notifier.loadAccountDetails(tUserId);

        expect(notifier.state.isLoading, false);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.learnerDetails, isNull);
      });
    });

    group('updateAccountDetails', () {
      test('should update state with details on success', () async {
        final upsertAccountDetails = MockUpsertAccountDetails();
        final response = _fakeResponse(teacher: tTeacher);
        when(() => upsertAccountDetails(any())).thenAnswer(
          (_) async => Right(response),
        );
        final notifier = _buildNotifier(upsertAccountDetails: upsertAccountDetails);

        await notifier.updateAccountDetails(
          userId: tUserId,
          teacherDetails: {'license_id': 'lic-1'},
        );

        expect(notifier.state.isLoading, false);
        expect(notifier.state.teacherDetails, isNotNull);
        expect(notifier.state.teacherDetails?.licenseId, 'lic-1');
        expect(notifier.state.successMessage, 'Account details updated successfully');
      });

      test('should update state with error on failure', () async {
        final upsertAccountDetails = MockUpsertAccountDetails();
        when(() => upsertAccountDetails(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        final notifier = _buildNotifier(upsertAccountDetails: upsertAccountDetails);

        await notifier.updateAccountDetails(
          userId: tUserId,
          learnerDetails: {'lrn': '123'},
        );

        expect(notifier.state.isLoading, false);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.successMessage, isNull);
      });
    });

    group('clearMessages', () {
      test('should clear error and successMessage', () {
        final notifier = _buildNotifier();
        notifier.state = notifier.state.copyWith(
          error: 'some error',
          successMessage: 'some success',
        );

        notifier.clearMessages();

        expect(notifier.state.error, isNull);
        expect(notifier.state.successMessage, isNull);
      });
    });

    group('clearDetails', () {
      test('should clear learner and teacher details', () {
        final notifier = _buildNotifier();
        notifier.state = notifier.state.copyWith(
          learnerDetails: tLearner,
          teacherDetails: tTeacher,
        );

        notifier.clearDetails();

        expect(notifier.state.learnerDetails, isNull);
        expect(notifier.state.teacherDetails, isNull);
      });
    });
  });
}
