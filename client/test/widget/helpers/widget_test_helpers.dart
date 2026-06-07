import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/domain/assignments/usecases/create_submission.dart';
import 'package:likha/domain/assignments/usecases/delete_assignment.dart';
import 'package:likha/domain/assignments/usecases/delete_file.dart';
import 'package:likha/domain/assignments/usecases/download_file.dart';
import 'package:likha/domain/assignments/usecases/get_assignment_detail.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/domain/assignments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assignments/usecases/get_submissions.dart';
import 'package:likha/domain/assignments/usecases/grade_submission.dart';
import 'package:likha/domain/assignments/usecases/publish_assignment.dart';
import 'package:likha/domain/assignments/usecases/reorder_assignment.dart';
import 'package:likha/domain/assignments/usecases/return_submission.dart';
import 'package:likha/domain/assignments/usecases/submit_assignment.dart';
import 'package:likha/domain/assignments/usecases/unpublish_assignment.dart';
import 'package:likha/domain/assignments/usecases/update_assignment.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/domain/auth/usecases/activate_account.dart';
import 'package:likha/domain/auth/usecases/check_username.dart';
import 'package:likha/domain/auth/usecases/get_current_user.dart';
import 'package:likha/domain/auth/usecases/login.dart';
import 'package:likha/domain/auth/usecases/logout.dart';
import 'package:likha/domain/classes/usecases/add_student.dart';
import 'package:likha/domain/classes/usecases/create_class.dart';
import 'package:likha/domain/classes/usecases/delete_class.dart';
import 'package:likha/domain/classes/usecases/get_all_classes.dart';
import 'package:likha/domain/classes/usecases/get_class_detail.dart';
import 'package:likha/domain/classes/usecases/get_my_classes.dart';
import 'package:likha/domain/classes/usecases/get_participants.dart';
import 'package:likha/domain/classes/usecases/remove_student.dart';
import 'package:likha/domain/classes/usecases/search_students.dart';
import 'package:likha/domain/classes/usecases/update_class.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/auth_notifier.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:mocktail/mocktail.dart';

export 'package:flutter_test/flutter_test.dart';
export 'package:mocktail/mocktail.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Mock GetIt-managed singletons ─────────────────────────────────────────────

class MockSchoolSetupService extends Mock implements SchoolSetupService {}
class MockDioClient extends Mock implements DioClient {}
class MockSyncManager extends Mock implements SyncManager {}
class MockSyncQueue extends Mock implements SyncQueue {}

// ── Mock use cases — auth ─────────────────────────────────────────────────────

class _MockLogin extends Mock implements Login {}
class _MockLogout extends Mock implements Logout {}
class _MockGetCurrentUser extends Mock implements GetCurrentUser {}
class _MockCheckUsername extends Mock implements CheckUsername {}
class _MockActivateAccount extends Mock implements ActivateAccount {}
class _MockSyncQueue extends Mock implements SyncQueue {}

// ── Mock use cases — assignments ──────────────────────────────────────────────

class _MockCreateAssignment extends Mock implements CreateAssignment {}
class _MockGetAssignments extends Mock implements GetAssignments {}
class _MockGetAssignmentDetail extends Mock implements GetAssignmentDetail {}
class _MockUpdateAssignment extends Mock implements UpdateAssignment {}
class _MockDeleteAssignment extends Mock implements DeleteAssignment {}
class _MockPublishAssignment extends Mock implements PublishAssignment {}
class _MockUnpublishAssignment extends Mock implements UnpublishAssignment {}
class _MockGetSubmissions extends Mock implements GetAssignmentSubmissions {}
class _MockGetSubmissionDetail extends Mock implements GetAssignmentSubmissionDetail {}
class _MockGradeSubmission extends Mock implements GradeSubmission {}
class _MockReturnSubmission extends Mock implements ReturnSubmission {}
class _MockCreateSubmission extends Mock implements CreateSubmission {}
class _MockUploadFile extends Mock implements UploadFile {}
class _MockDeleteFile extends Mock implements DeleteFile {}
class _MockSubmitAssignment extends Mock implements SubmitAssignment {}
class _MockDownloadFile extends Mock implements DownloadFile {}
class _MockReorderAssignments extends Mock implements ReorderAllAssignments {}

// ── Mock use cases — classes ──────────────────────────────────────────────────

class _MockCreateClass extends Mock implements CreateClass {}
class _MockGetMyClasses extends Mock implements GetMyClasses {}
class _MockGetAllClasses extends Mock implements GetAllClasses {}
class _MockGetClassDetail extends Mock implements GetClassDetail {}
class _MockUpdateClass extends Mock implements UpdateClass {}
class _MockAddStudent extends Mock implements AddStudent {}
class _MockRemoveStudent extends Mock implements RemoveStudent {}
class _MockSearchStudents extends Mock implements SearchStudents {}
class _MockGetParticipants extends Mock implements GetParticipants {}
class _MockDeleteClass extends Mock implements DeleteClass {}

// ── Fake Riverpod notifiers ───────────────────────────────────────────────────

/// Stub [AuthNotifier] with a fixed [AuthState] and no side effects.
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
    state = _fixedState;
  }

  @override
  Future<void> checkAuthStatus() async {}
}

/// Stub [AssignmentNotifier] with a fixed [AssignmentState] and no-op loads.
/// Requires [DataEventBus] to be registered in GetIt (done by [setUpMockDi]).
class FakeAssignmentNotifier extends AssignmentNotifier {
  final AssignmentState _fixedState;

  FakeAssignmentNotifier([AssignmentState? initialState])
      : _fixedState = initialState ?? AssignmentState(),
        super(
          _MockCreateAssignment(),
          _MockGetAssignments(),
          _MockGetAssignmentDetail(),
          _MockUpdateAssignment(),
          _MockDeleteAssignment(),
          _MockPublishAssignment(),
          _MockUnpublishAssignment(),
          _MockGetSubmissions(),
          _MockGetSubmissionDetail(),
          _MockGradeSubmission(),
          _MockReturnSubmission(),
          _MockCreateSubmission(),
          _MockUploadFile(),
          _MockDeleteFile(),
          _MockSubmitAssignment(),
          _MockDownloadFile(),
          _MockReorderAssignments(),
        ) {
    state = _fixedState;
  }

  @override
  Future<void> loadAssignments(String classId,
      {bool publishedOnly = false, bool skipBackgroundRefresh = false}) async {}

  @override
  Future<void> loadAssignmentDetail(String assignmentId) async {}

  @override
  Future<void> loadSubmissionDetail(String submissionId) async {}
}

/// Stub [ClassNotifier] with a fixed [ClassState] and no-op loads.
/// Requires [DataEventBus] to be registered in GetIt (done by [setUpMockDi]).
class FakeClassNotifier extends ClassNotifier {
  final ClassState _fixedState;

  FakeClassNotifier([ClassState? initialState])
      : _fixedState = initialState ?? ClassState(),
        super(
          _MockCreateClass(),
          _MockGetMyClasses(),
          _MockGetAllClasses(),
          _MockGetClassDetail(),
          _MockUpdateClass(),
          _MockAddStudent(),
          _MockRemoveStudent(),
          _MockSearchStudents(),
          _MockGetParticipants(),
          _MockDeleteClass(),
        ) {
    state = _fixedState;
  }

  @override
  Future<void> loadClassDetail(String classId) async {}
}

/// Stub [TosNotifier] with a fixed [TosState]. TosNotifier has a no-arg constructor.
class FakeTosNotifier extends TosNotifier {
  FakeTosNotifier([TosState? initialState]) : super() {
    if (initialState != null) state = initialState;
  }
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

  // Real instances — no mocking needed, they never emit/do anything in tests.
  _register<DataEventBus>(getIt, DataEventBus());
  _register<ServerClockService>(getIt, ServerClockService());
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
