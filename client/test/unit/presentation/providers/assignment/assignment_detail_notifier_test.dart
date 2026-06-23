import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/assignments/usecases/get_assignment_detail.dart';
import 'package:likha/presentation/providers/assignment/assignment_detail_provider.dart';

import '../../../../helpers/fake_entities.dart';

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGetAssignmentDetail extends Mock implements GetAssignmentDetail {}

void main() {
  final tAssignment = FakeEntities.assignment();

  group('AssignmentDetailNotifier', () {
    group('loadAssignmentDetail', () {
      test('populates currentAssignment on success', () async {
        final mockGet = MockGetAssignmentDetail();
        final notifier = AssignmentDetailNotifier(_FakeRef(), mockGet);

        when(() => mockGet(any()))
            .thenAnswer((_) async => Right(tAssignment));

        await notifier.loadAssignmentDetail('a-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.currentAssignment, isNotNull);
        expect(notifier.state.currentAssignment!.id, tAssignment.id);
        expect(notifier.state.error, isNull);
      });

      test('sets error on failure', () async {
        final mockGet = MockGetAssignmentDetail();
        final notifier = AssignmentDetailNotifier(_FakeRef(), mockGet);

        when(() => mockGet(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Not found')));

        await notifier.loadAssignmentDetail('a-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.currentAssignment, isNull);
      });
    });

    group('clearMessages', () {
      test('clears error and successMessage', () {
        final notifier =
            AssignmentDetailNotifier(_FakeRef(), MockGetAssignmentDetail());
        notifier.state = notifier.state.copyWith(
          error: 'Some error',
          successMessage: 'Some success',
        );
        notifier.clearMessages();
        expect(notifier.state.error, isNull);
        expect(notifier.state.successMessage, isNull);
      });
    });

    group('clearCurrentAssignment', () {
      test('clears currentAssignment', () {
        final notifier =
            AssignmentDetailNotifier(_FakeRef(), MockGetAssignmentDetail());
        notifier.state = notifier.state.copyWith(currentAssignment: FakeEntities.assignment());
        notifier.clearCurrentAssignment();
        expect(notifier.state.currentAssignment, isNull);
      });
    });

    group('initial state', () {
      test('starts with null assignment and not loading', () {
        final notifier =
            AssignmentDetailNotifier(_FakeRef(), MockGetAssignmentDetail());
        expect(notifier.state.currentAssignment, isNull);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNull);
      });
    });
  });
}
