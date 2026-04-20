import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/auth/usecases/activate_account.dart';
import 'package:likha/domain/auth/usecases/check_username.dart';
import 'package:likha/domain/auth/usecases/get_current_user.dart';
import 'package:likha/domain/auth/usecases/login.dart';
import 'package:likha/domain/auth/usecases/logout.dart';
import 'package:likha/presentation/providers/auth_notifier.dart';

import '../../../helpers/fake_entities.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockLogin extends Mock implements Login {}
class MockLogout extends Mock implements Logout {}
class MockGetCurrentUser extends Mock implements GetCurrentUser {}
class MockCheckUsername extends Mock implements CheckUsername {}
class MockActivateAccount extends Mock implements ActivateAccount {}
class MockSyncQueue extends Mock implements SyncQueue {}

// ── Helpers ───────────────────────────────────────────────────────────────────

AuthNotifier _buildNotifier({
  MockLogin? login,
  MockLogout? logout,
  MockCheckUsername? checkUsername,
  MockActivateAccount? activateAccount,
  MockSyncQueue? syncQueue,
}) {
  return AuthNotifier(
    login ?? MockLogin(),
    logout ?? MockLogout(),
    MockGetCurrentUser(),
    checkUsername ?? MockCheckUsername(),
    activateAccount ?? MockActivateAccount(),
    syncQueue ?? MockSyncQueue(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final tUser = FakeEntities.user();

  setUpAll(() {
    registerFallbackValue(LoginParams(
      username: 'user1',
      password: 'secret',
    ));
    registerFallbackValue(ActivateAccountParams(
      username: 'user1',
      password: 'secret',
      confirmPassword: 'secret',
    ));
  });

  group('AuthNotifier', () {
    // ── login ─────────────────────────────────────────────────────────────

    group('login', () {
      test('sets isAuthenticated and user on success', () async {
        final mockLogin = MockLogin();
        final notifier = _buildNotifier(login: mockLogin);

        when(() => mockLogin(any())).thenAnswer((_) async => Right(tUser));

        await notifier.login(username: 'user1', password: 'secret');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.isAuthenticated, isTrue);
        expect(notifier.state.user?.id, tUser.id);
        expect(notifier.state.error, isNull);
      });

      test('sets attemptsRemaining on InvalidCredentialsFailure', () async {
        final mockLogin = MockLogin();
        final notifier = _buildNotifier(login: mockLogin);

        when(() => mockLogin(any())).thenAnswer((_) async =>
            Left(InvalidCredentialsFailure('Invalid credentials', attemptsRemaining: 2)));

        await notifier.login(username: 'user1', password: 'wrong');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.isAuthenticated, isFalse);
        expect(notifier.state.attemptsRemaining, 2);
      });

      test('sets lockoutRemainingSeconds on TooManyRequestsFailure', () async {
        final mockLogin = MockLogin();
        final notifier = _buildNotifier(login: mockLogin);

        when(() => mockLogin(any())).thenAnswer((_) async =>
            Left(TooManyRequestsFailure('Too many attempts', remainingSeconds: 30)));

        await notifier.login(username: 'user1', password: 'wrong');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.isAuthenticated, isFalse);
        expect(notifier.state.lockoutRemainingSeconds, greaterThan(0));
      });

      test('sets error on generic ServerFailure', () async {
        final mockLogin = MockLogin();
        final notifier = _buildNotifier(login: mockLogin);

        when(() => mockLogin(any()))
            .thenAnswer((_) async => Left(ServerFailure('Network error')));

        await notifier.login(username: 'user1', password: 'secret');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.isAuthenticated, isFalse);
        expect(notifier.state.error, isNotNull);
      });
    });

    // ── logout ────────────────────────────────────────────────────────────

    group('logout', () {
      test('clears user and isAuthenticated on success', () async {
        final mockLogin = MockLogin();
        final mockLogout = MockLogout();
        final notifier = _buildNotifier(login: mockLogin, logout: mockLogout);

        // First login to set state
        when(() => mockLogin(any())).thenAnswer((_) async => Right(tUser));
        await notifier.login(username: 'user1', password: 'secret');
        expect(notifier.state.isAuthenticated, isTrue);

        // Then logout
        when(() => mockLogout()).thenAnswer((_) async => const Right(null));
        await notifier.logout();

        expect(notifier.state.isAuthenticated, isFalse);
        expect(notifier.state.user, isNull);
      });
    });

    // ── checkUsernameForLogin ─────────────────────────────────────────────

    group('checkUsernameForLogin', () {
      test('sets loginUsername when account is activated', () async {
        final mockCheck = MockCheckUsername();
        final notifier = _buildNotifier(checkUsername: mockCheck);

        when(() => mockCheck(any())).thenAnswer((_) async => Right(
            FakeEntities.checkUsernameResult(accountStatus: 'activated')));

        await notifier.checkUsernameForLogin('user1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.loginUsername, isNotNull);
        expect(notifier.state.error, isNull);
      });

      test('sets pendingActivationUsername when account is pending activation', () async {
        final mockCheck = MockCheckUsername();
        final notifier = _buildNotifier(checkUsername: mockCheck);

        when(() => mockCheck(any())).thenAnswer((_) async => Right(
            FakeEntities.checkUsernameResult(accountStatus: 'pending_activation')));

        await notifier.checkUsernameForLogin('user1');

        expect(notifier.state.pendingActivationUsername, isNotNull);
        expect(notifier.state.loginUsername, isNull);
      });

      test('sets error when username not found (404)', () async {
        final mockCheck = MockCheckUsername();
        final notifier = _buildNotifier(checkUsername: mockCheck);

        when(() => mockCheck(any())).thenAnswer((_) async =>
            Left(ServerFailure('Username does not exist', statusCode: 404)));

        await notifier.checkUsernameForLogin('unknown');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.loginUsername, isNull);
      });
    });

    // ── initial state ─────────────────────────────────────────────────────

    group('initial state', () {
      test('starts unauthenticated and not loading', () {
        final notifier = _buildNotifier();
        expect(notifier.state.isAuthenticated, isFalse);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.user, isNull);
        expect(notifier.state.error, isNull);
      });
    });
  });
}
