import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/auth/usecases/create_account.dart';
import 'package:likha/domain/auth/usecases/delete_account.dart';
import 'package:likha/domain/auth/usecases/get_all_accounts.dart';
import 'package:likha/domain/auth/usecases/lock_account.dart';
import 'package:likha/domain/auth/usecases/reset_account.dart';
import 'package:likha/domain/auth/usecases/update_account.dart';
import 'package:likha/presentation/providers/admin/account_management_provider.dart';

import '../../../../helpers/fake_entities.dart';

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGetAllAccounts extends Mock implements GetAllAccounts {}
class MockCreateAccount extends Mock implements CreateAccount {}
class MockResetAccount extends Mock implements ResetAccount {}
class MockLockAccount extends Mock implements LockAccount {}
class MockUpdateAccount extends Mock implements UpdateAccount {}
class MockDeleteAccount extends Mock implements DeleteAccount {}

AccountManagementNotifier _buildNotifier({
  Ref? ref,
  MockGetAllAccounts? getAllAccounts,
  MockCreateAccount? createAccount,
  MockResetAccount? resetAccount,
  MockLockAccount? lockAccount,
  MockUpdateAccount? updateAccount,
  MockDeleteAccount? deleteAccount,
}) {
  return AccountManagementNotifier(
    ref ?? _FakeRef(),
    getAllAccounts ?? MockGetAllAccounts(),
    createAccount ?? MockCreateAccount(),
    resetAccount ?? MockResetAccount(),
    lockAccount ?? MockLockAccount(),
    updateAccount ?? MockUpdateAccount(),
    deleteAccount ?? MockDeleteAccount(),
  );
}

void main() {
  final tUser = FakeEntities.user();
  final tTeacher = FakeEntities.teacher();
  final tAccounts = [tUser, tTeacher];
  const tFailure = ServerFailure('Server error');

  setUpAll(() {
    registerFallbackValue(CreateAccountParams(
      username: 'fallback',
      firstName: 'F',
      lastName: 'L',
      role: 'student',
    ));
  });

  group('AccountManagementNotifier', () {
    group('loadAccounts', () {
      test('should update state with accounts on success', () async {
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => Right(tAccounts),
        );
        final notifier = _buildNotifier(getAllAccounts: getAllAccounts);

        await notifier.loadAccounts();

        expect(notifier.state.accounts, tAccounts);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.error, isNull);
      });

      test('should update state with error on failure', () async {
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => const Left(tFailure),
        );
        final notifier = _buildNotifier(getAllAccounts: getAllAccounts);

        await notifier.loadAccounts();

        expect(notifier.state.isLoading, false);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.accounts, isEmpty);
      });
    });

    group('createAccount', () {
      test('should optimistically add temp user and replace on success', () async {
        final createAccount = MockCreateAccount();
        final realUser = FakeEntities.user(id: 'real-1');
        when(() => createAccount(any())).thenAnswer(
          (_) async => Right(MutationResult(
            entity: realUser,
            status: SyncStatus.synced,
          )),
        );
        final notifier = _buildNotifier(createAccount: createAccount);

        await notifier.createAccount(
          username: 'newuser',
          firstName: 'New',
          lastName: 'User',
          role: 'student',
        );

        expect(notifier.state.accounts, isNotEmpty);
        expect(notifier.state.accounts.first.id, 'real-1');
        expect(notifier.state.successMessage, 'Account created successfully');
        expect(notifier.state.error, isNull);
      });

      test('should rollback accounts on failure', () async {
        final createAccount = MockCreateAccount();
        when(() => createAccount(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        final notifier = _buildNotifier(createAccount: createAccount);

        await notifier.createAccount(
          username: 'newuser',
          firstName: 'New',
          lastName: 'User',
          role: 'student',
        );

        expect(notifier.state.accounts, isEmpty);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.successMessage, isNull);
      });
    });

    group('resetAccount', () {
      test('should optimistically update and replace on success', () async {
        final resetAccount = MockResetAccount();
        final resetUser = FakeEntities.user(accountStatus: 'pending_activation', isActive: false);
        when(() => resetAccount(tUser.id)).thenAnswer(
          (_) async => Right(MutationResult(
            entity: resetUser,
            status: SyncStatus.synced,
          )),
        );
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => Right([tUser]),
        );
        final notifier = _buildNotifier(
          resetAccount: resetAccount,
          getAllAccounts: getAllAccounts,
        );
        await notifier.loadAccounts();

        await notifier.resetAccount(tUser.id);

        final updated = notifier.state.accounts.firstWhere((u) => u.id == tUser.id);
        expect(updated.accountStatus, 'pending_activation');
        expect(updated.isActive, false);
        expect(notifier.state.successMessage, 'Account reset successfully');
      });

      test('should rollback on failure', () async {
        final resetAccount = MockResetAccount();
        when(() => resetAccount(tUser.id)).thenAnswer(
          (_) async => const Left(tFailure),
        );
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => Right([tUser]),
        );
        final notifier = _buildNotifier(
          resetAccount: resetAccount,
          getAllAccounts: getAllAccounts,
        );
        await notifier.loadAccounts();

        await notifier.resetAccount(tUser.id);

        expect(notifier.state.accounts.first.id, tUser.id);
        expect(notifier.state.accounts.first.accountStatus, tUser.accountStatus);
        expect(notifier.state.error, isNotNull);
      });
    });

    group('lockAccount', () {
      test('should optimistically lock and replace on success', () async {
        final lockAccount = MockLockAccount();
        final lockedUser = FakeEntities.user(accountStatus: 'locked', isActive: false);
        when(() => lockAccount(any())).thenAnswer(
          (_) async => Right(MutationResult(
            entity: lockedUser,
            status: SyncStatus.synced,
          )),
        );
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => Right([tUser]),
        );
        final notifier = _buildNotifier(
          lockAccount: lockAccount,
          getAllAccounts: getAllAccounts,
        );
        await notifier.loadAccounts();

        await notifier.lockAccount(tUser.id, true);

        final updated = notifier.state.accounts.firstWhere((u) => u.id == tUser.id);
        expect(updated.accountStatus, 'locked');
        expect(updated.isActive, false);
        expect(notifier.state.successMessage, 'Account locked');
      });

      test('should rollback on failure', () async {
        final lockAccount = MockLockAccount();
        when(() => lockAccount(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => Right([tUser]),
        );
        final notifier = _buildNotifier(
          lockAccount: lockAccount,
          getAllAccounts: getAllAccounts,
        );
        await notifier.loadAccounts();

        await notifier.lockAccount(tUser.id, true);

        expect(notifier.state.accounts.first.accountStatus, tUser.accountStatus);
        expect(notifier.state.error, isNotNull);
      });
    });

    group('updateAccount', () {
      test('should optimistically update and replace on success', () async {
        final updateAccount = MockUpdateAccount();
        final updatedUser = FakeEntities.user(firstName: 'Updated');
        when(() => updateAccount(any())).thenAnswer(
          (_) async => Right(MutationResult(
            entity: updatedUser,
            status: SyncStatus.synced,
          )),
        );
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => Right([tUser]),
        );
        final notifier = _buildNotifier(
          updateAccount: updateAccount,
          getAllAccounts: getAllAccounts,
        );
        await notifier.loadAccounts();

        await notifier.updateAccount(userId: tUser.id, firstName: 'Updated');

        expect(notifier.state.accounts.first.firstName, 'Updated');
        expect(notifier.state.successMessage, 'Account updated successfully');
      });

      test('should rollback on failure', () async {
        final updateAccount = MockUpdateAccount();
        when(() => updateAccount(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => Right([tUser]),
        );
        final notifier = _buildNotifier(
          updateAccount: updateAccount,
          getAllAccounts: getAllAccounts,
        );
        await notifier.loadAccounts();

        await notifier.updateAccount(userId: tUser.id, firstName: 'Updated');

        expect(notifier.state.accounts.first.firstName, tUser.firstName);
        expect(notifier.state.error, isNotNull);
      });
    });

    group('deleteAccount', () {
      test('should optimistically remove and set success on success', () async {
        final deleteAccount = MockDeleteAccount();
        when(() => deleteAccount(userId: tUser.id)).thenAnswer(
          (_) async => const Right(null),
        );
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => Right([tUser]),
        );
        final notifier = _buildNotifier(
          deleteAccount: deleteAccount,
          getAllAccounts: getAllAccounts,
        );
        await notifier.loadAccounts();

        await notifier.deleteAccount(tUser.id);

        expect(notifier.state.accounts.where((u) => u.id == tUser.id), isEmpty);
        expect(notifier.state.successMessage, 'Account deleted successfully');
      });

      test('should rollback on failure', () async {
        final deleteAccount = MockDeleteAccount();
        when(() => deleteAccount(userId: tUser.id)).thenAnswer(
          (_) async => const Left(tFailure),
        );
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => Right([tUser]),
        );
        final notifier = _buildNotifier(
          deleteAccount: deleteAccount,
          getAllAccounts: getAllAccounts,
        );
        await notifier.loadAccounts();

        await notifier.deleteAccount(tUser.id);

        expect(notifier.state.accounts.where((u) => u.id == tUser.id), isNotEmpty);
        expect(notifier.state.error, isNotNull);
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

    group('cacheAccountsOffline', () {
      test('should update state with accounts on success', () async {
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => Right(tAccounts),
        );
        final notifier = _buildNotifier(getAllAccounts: getAllAccounts);

        await notifier.cacheAccountsOffline();

        expect(notifier.state.accounts, tAccounts);
      });

      test('should silently ignore on failure', () async {
        final getAllAccounts = MockGetAllAccounts();
        when(() => getAllAccounts()).thenAnswer(
          (_) async => const Left(tFailure),
        );
        final notifier = _buildNotifier(getAllAccounts: getAllAccounts);

        await notifier.cacheAccountsOffline();

        expect(notifier.state.accounts, isEmpty);
        expect(notifier.state.error, isNull);
      });
    });
  });
}
