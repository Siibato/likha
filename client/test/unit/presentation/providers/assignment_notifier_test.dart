import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/domain/assignments/usecases/delete_assignment.dart';
import 'package:likha/domain/assignments/usecases/download_file.dart';
import 'package:likha/domain/assignments/usecases/get_assignment_detail.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/domain/assignments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assignments/usecases/get_submissions.dart';
import 'package:likha/domain/assignments/usecases/grade_submission.dart';
import 'package:likha/domain/assignments/usecases/publish_assignment.dart';
import 'package:likha/domain/assignments/usecases/unpublish_assignment.dart';
import 'package:likha/domain/assignments/usecases/reorder_assignment.dart';
import 'package:likha/domain/assignments/usecases/return_submission.dart';
import 'package:likha/domain/assignments/usecases/submit_assignment.dart';
import 'package:likha/domain/assignments/usecases/update_assignment.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/domain/assignments/usecases/create_submission.dart';
import 'package:likha/domain/assignments/usecases/delete_file.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

import '../../../helpers/fake_entities.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockGetAssignments extends Mock implements GetAssignments {}
class MockGetAssignmentDetail extends Mock implements GetAssignmentDetail {}
class MockCreateAssignment extends Mock implements CreateAssignment {}
class MockUpdateAssignment extends Mock implements UpdateAssignment {}
class MockDeleteAssignment extends Mock implements DeleteAssignment {}
class MockPublishAssignment extends Mock implements PublishAssignment {}
class MockUnpublishAssignment extends Mock implements UnpublishAssignment {}
class MockGetAssignmentSubmissions extends Mock implements GetAssignmentSubmissions {}
class MockGetAssignmentSubmissionDetail extends Mock implements GetAssignmentSubmissionDetail {}
class MockGradeSubmission extends Mock implements GradeSubmission {}
class MockReturnSubmission extends Mock implements ReturnSubmission {}
class MockCreateSubmission extends Mock implements CreateSubmission {}
class MockUploadFile extends Mock implements UploadFile {}
class MockDeleteFile extends Mock implements DeleteFile {}
class MockSubmitAssignment extends Mock implements SubmitAssignment {}
class MockDownloadFile extends Mock implements DownloadFile {}
class MockReorderAllAssignments extends Mock implements ReorderAllAssignments {}
class MockGradingRepository extends Mock implements GradingRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

AssignmentNotifier _buildNotifier({
  MockGetAssignments? getAssignments,
  MockCreateAssignment? createAssignment,
  MockDeleteAssignment? deleteAssignment,
}) {
  return AssignmentNotifier(
    createAssignment ?? MockCreateAssignment(),
    getAssignments ?? MockGetAssignments(),
    MockGetAssignmentDetail(),
    MockUpdateAssignment(),
    deleteAssignment ?? MockDeleteAssignment(),
    MockPublishAssignment(),
    MockUnpublishAssignment(),
    MockGetAssignmentSubmissions(),
    MockGetAssignmentSubmissionDetail(),
    MockGradeSubmission(),
    MockReturnSubmission(),
    MockCreateSubmission(),
    MockUploadFile(),
    MockDeleteFile(),
    MockSubmitAssignment(),
    MockDownloadFile(),
    MockReorderAllAssignments(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final tAssignment = FakeEntities.assignment();

  setUpAll(() {
    GetIt.instance.registerSingleton<DataEventBus>(DataEventBus());
    final mockGradingRepo = MockGradingRepository();
    when(() => mockGradingRepo.findGradeItemBySourceId(any()))
        .thenAnswer((_) async => const Right(null));
    GetIt.instance.registerSingleton<GradingRepository>(mockGradingRepo);
    registerFallbackValue(CreateAssignmentParams(
      classId: 'c-1',
      title: 'T',
      instructions: 'I',
      totalPoints: 100,
      allowsTextSubmission: true,
      allowsFileSubmission: false,
      dueAt: '2025-06-01T00:00:00',
    ));
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('AssignmentNotifier', () {
    group('loadAssignments', () {
      test('sets isLoading then populates assignments on success', () async {
        final mockGet = MockGetAssignments();
        final notifier = _buildNotifier(getAssignments: mockGet);

        when(() => mockGet(any(), publishedOnly: any(named: 'publishedOnly'), skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'))).thenAnswer((_) async => Right([tAssignment]));

        final states = <AssignmentState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.loadAssignments('c-1');

        expect(states.last.isLoading, isFalse);
        expect(states.last.assignments.length, 1);
        expect(states.last.error, isNull);
      });

      test('sets error on failure', () async {
        final mockGet = MockGetAssignments();
        final notifier = _buildNotifier(getAssignments: mockGet);

        when(() => mockGet(any(), publishedOnly: any(named: 'publishedOnly'), skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
            .thenAnswer((_) async => const Left(ServerFailure('Network error')));

        await notifier.loadAssignments('c-1');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.assignments, isEmpty);
      });
    });

    group('createAssignment', () {
      test('sets successMessage on success', () async {
        final mockCreate = MockCreateAssignment();
        final mockGet = MockGetAssignments();
        final notifier = _buildNotifier(
          getAssignments: mockGet,
          createAssignment: mockCreate,
        );

        when(() => mockCreate(any())).thenAnswer((_) async => Right(tAssignment));
        when(() => mockGet(any(), publishedOnly: any(named: 'publishedOnly'), skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'))).thenAnswer((_) async => Right([tAssignment]));

        await notifier.createAssignment(CreateAssignmentParams(
          classId: 'c-1',
          title: 'HW 1',
          instructions: 'Do it',
          totalPoints: 50,
          allowsTextSubmission: true,
          allowsFileSubmission: false,
          dueAt: '2025-06-01T00:00:00',
        ));

        expect(notifier.state.successMessage, isNotNull);
        expect(notifier.state.error, isNull);
      });

      test('sets error on failure', () async {
        final mockCreate = MockCreateAssignment();
        final notifier = _buildNotifier(createAssignment: mockCreate);

        when(() => mockCreate(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Create failed')));

        await notifier.createAssignment(CreateAssignmentParams(
          classId: 'c-1',
          title: 'HW 1',
          instructions: 'Do it',
          totalPoints: 50,
          allowsTextSubmission: true,
          allowsFileSubmission: false,
          dueAt: '2025-06-01T00:00:00',
        ));

        expect(notifier.state.error, isNotNull);
        expect(notifier.state.successMessage, isNull);
      });
    });

    group('deleteAssignment', () {
      test('removes assignment from state and sets successMessage on success', () async {
        final mockGet = MockGetAssignments();
        final mockDelete = MockDeleteAssignment();

        final notifier = _buildNotifier(
          getAssignments: mockGet,
          deleteAssignment: mockDelete,
        );

        // Seed the state with one assignment
        when(() => mockGet(any(), publishedOnly: any(named: 'publishedOnly'), skipBackgroundRefresh: any(named: 'skipBackgroundRefresh'))).thenAnswer((_) async => Right([tAssignment]));
        await notifier.loadAssignments('c-1');

        when(() => mockDelete(any())).thenAnswer((_) async => const Right(null));

        await notifier.deleteAssignment(tAssignment.id);

        expect(notifier.state.error, isNull);
        expect(notifier.state.successMessage, isNotNull);
      });

      test('sets error on failure', () async {
        final mockDelete = MockDeleteAssignment();
        final notifier = _buildNotifier(deleteAssignment: mockDelete);

        when(() => mockDelete(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Delete failed')));

        await notifier.deleteAssignment('a-1');

        expect(notifier.state.error, isNotNull);
      });
    });

    group('initial state', () {
      test('starts with empty assignments and not loading', () {
        final notifier = _buildNotifier();
        expect(notifier.state.assignments, isEmpty);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNull);
      });
    });
  });
}
