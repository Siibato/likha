import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/auth/usecases/activate_account.dart';
import 'package:likha/domain/auth/usecases/check_username.dart';
import 'package:likha/domain/auth/usecases/get_current_user.dart';
import 'package:likha/domain/auth/usecases/login.dart';
import 'package:likha/domain/auth/usecases/logout.dart';
import 'package:likha/presentation/providers/auth_notifier.dart';
import 'package:mocktail/mocktail.dart';

export 'package:flutter_test/flutter_test.dart';
export 'package:mocktail/mocktail.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Mock GetIt-managed singletons ─────────────────────────────────────────────

class MockSchoolSetupService extends Mock implements SchoolSetupService {}
class MockDioClient extends Mock implements DioClient {}
class MockSyncManager extends Mock implements SyncManager {}
class MockSyncQueue extends Mock implements SyncQueue {}

// ── Mock use cases (for FakeAuthNotifier) ────────────────────────────────────

class _MockLogin extends Mock implements Login {}
class _MockLogout extends Mock implements Logout {}
class _MockGetCurrentUser extends Mock implements GetCurrentUser {}
class _MockCheckUsername extends Mock implements CheckUsername {}
class _MockActivateAccount extends Mock implements ActivateAccount {}
class _MockSyncQueue extends Mock implements SyncQueue {}

// ── Fake Riverpod notifiers ───────────────────────────────────────────────────

/// A stub [AuthNotifier] that holds a fixed [AuthState] with no side effects.
/// Override [authProvider] with this in widget tests.
class FakeAuthNotifier extends AuthNotifier {
  final AuthState _fixedState;

  FakeAuthNotifier([AuthState? initialState])
      : _fixedState = initialState ?? AuthState(),
        super(
          _MockLogin(),
          _MockLogout(),
          _MockGetCurrentUser(),
          _MockCheckUsername(),
          _MockActivateAccount(),
          _MockSyncQueue(),
        ) {
    // Immediately update to the desired state
    state = _fixedState;
  }

  @override
  Future<void> checkAuthStatus() async {}
}

// ── GetIt setup/teardown ──────────────────────────────────────────────────────

/// Registers minimal mock singletons so pages that call di.sl<>() don't crash.
/// Call in [setUp], always pair with [tearDownMockDi] in [tearDown].
void setUpMockDi({
  MockSchoolSetupService? schoolSetupService,
  MockDioClient? dioClient,
  MockSyncManager? syncManager,
  MockSyncQueue? syncQueue,
}) {
  final getIt = GetIt.instance;

  final svc = schoolSetupService ?? MockSchoolSetupService();
  when(() => svc.getSchoolConfig()).thenAnswer((_) async => null);
  when(() => svc.clearSchoolConfig()).thenAnswer((_) async {});
  _register<SchoolSetupService>(getIt, svc);

  final dio = dioClient ?? MockDioClient();
  _register<DioClient>(getIt, dio);

  final sync = syncManager ?? MockSyncManager();
  when(() => sync.state).thenReturn(const SyncState(
    phase: SyncPhase.idle,
    pendingCount: 0,
    failedCount: 0,
  ));
  when(() => sync.start()).thenReturn(null);
  when(() => sync.reset()).thenReturn(null);
  when(() => sync.setStateListener(any())).thenReturn(null);
  _register<SyncManager>(getIt, sync);

  final queue = syncQueue ?? MockSyncQueue();
  when(() => queue.getAllRetriable()).thenAnswer((_) async => []);
  _register<SyncQueue>(getIt, queue);
}

void _register<T extends Object>(GetIt getIt, T instance) {
  if (getIt.isRegistered<T>()) getIt.unregister<T>();
  getIt.registerSingleton<T>(instance);
}

/// Resets GetIt after each test.
void tearDownMockDi() => GetIt.instance.reset();

// ── Widget scaffold helper ────────────────────────────────────────────────────

/// Wraps [child] in a [ProviderScope] + [MaterialApp] ready for widget tests.
Widget testScaffold(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}
