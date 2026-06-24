import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/auth/usecases/get_activity_logs.dart';
import 'package:likha/presentation/providers/admin/activity_log_provider.dart';

import '../../../../helpers/fake_entities.dart';

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGetActivityLogs extends Mock implements GetActivityLogs {}

ActivityLogNotifier _buildNotifier({
  Ref? ref,
  MockGetActivityLogs? getActivityLogs,
}) {
  return ActivityLogNotifier(
    ref ?? _FakeRef(),
    getActivityLogs ?? MockGetActivityLogs(),
  );
}

void main() {
  const tFailure = ServerFailure('Server error');
  const tUserId = 'user-1';
  final tLogs = [
    FakeEntities.activityLog(id: 'log-1', userId: tUserId, action: 'login'),
    FakeEntities.activityLog(id: 'log-2', userId: tUserId, action: 'logout'),
  ];

  group('ActivityLogNotifier', () {
    group('loadActivityLogs', () {
      test('should update state with logs on success', () async {
        final getActivityLogs = MockGetActivityLogs();
        when(() => getActivityLogs(tUserId)).thenAnswer(
          (_) async => Right(tLogs),
        );
        final notifier = _buildNotifier(getActivityLogs: getActivityLogs);

        await notifier.loadActivityLogs(tUserId);

        expect(notifier.state.activityLogs, tLogs);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.error, isNull);
      });

      test('should update state with error on failure', () async {
        final getActivityLogs = MockGetActivityLogs();
        when(() => getActivityLogs(tUserId)).thenAnswer(
          (_) async => const Left(tFailure),
        );
        final notifier = _buildNotifier(getActivityLogs: getActivityLogs);

        await notifier.loadActivityLogs(tUserId);

        expect(notifier.state.isLoading, false);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.activityLogs, isEmpty);
      });
    });

    group('clearActivityLogs', () {
      test('should clear activity logs', () {
        final getActivityLogs = MockGetActivityLogs();
        when(() => getActivityLogs(tUserId)).thenAnswer(
          (_) async => Right(tLogs),
        );
        final notifier = _buildNotifier(getActivityLogs: getActivityLogs);

        notifier.state = notifier.state.copyWith(activityLogs: tLogs);
        expect(notifier.state.activityLogs, isNotEmpty);

        notifier.clearActivityLogs();

        expect(notifier.state.activityLogs, isEmpty);
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
  });
}
