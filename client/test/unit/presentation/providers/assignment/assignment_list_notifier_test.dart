import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/domain/assignments/usecases/delete_assignment.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/domain/assignments/usecases/publish_assignment.dart';
import 'package:likha/domain/assignments/usecases/reorder_assignment.dart';
import 'package:likha/domain/assignments/usecases/unpublish_assignment.dart';
import 'package:likha/domain/assignments/usecases/update_assignment.dart';
import 'package:likha/presentation/providers/assignment/assignment_list_provider.dart';

import '../../../../helpers/fake_entities.dart';

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGetAssignments extends Mock implements GetAssignments {}
class MockCreateAssignment extends Mock implements CreateAssignment {}
class MockUpdateAssignment extends Mock implements UpdateAssignment {}
class MockDeleteAssignment extends Mock implements DeleteAssignment {}
class MockPublishAssignment extends Mock implements PublishAssignment {}
class MockUnpublishAssignment extends Mock implements UnpublishAssignment {}
class MockReorderAllAssignments extends Mock implements ReorderAllAssignments {}
class MockGradingRepository extends Mock implements GradingRepository {}

AssignmentListNotifier _buildNotifier({
  Ref? ref,
  MockGetAssignments? getAssignments,
  MockCreateAssignment? createAssignment,
  MockUpdateAssignment? updateAssignment,
  MockDeleteAssignment? deleteAssignment,
  MockPublishAssignment? publishAssignment,
  MockUnpublishAssignment? unpublishAssignment,
  MockReorderAllAssignments? reorderAllAssignments,
}) {
  return AssignmentListNotifier(
    ref ?? _FakeRef(),
    createAssignment ?? MockCreateAssignment(),
    getAssignments ?? MockGetAssignments(),
    updateAssignment ?? MockUpdateAssignment(),
    deleteAssignment ?? MockDeleteAssignment(),
    publishAssignment ?? MockPublishAssignment(),
    unpublishAssignment ?? MockUnpublishAssignment(),
    reorderAllAssignments ?? MockReorderAllAssignments(),
  );
}

void main() {
  final tAssignment = FakeEntities.assignment();

  setUpAll(() {
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

  group('AssignmentListNotifier', () {
    group('loadAssignments', () {
      test('sets isLoading then populates assignments on success', () async {
        final mockGet = MockGetAssignments();
        final notifier = _buildNotifier(getAssignments: mockGet);

        when(() => mockGet(any(),
                publishedOnly: any(named: 'publishedOnly'),
                skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
            .thenAnswer((_) async => Right([tAssignment]));

        final states = <AssignmentListState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.loadAssignments('c-1');

        expect(states.last.isLoading, isFalse);
        expect(states.last.assignments.length, 1);
        expect(states.last.error, isNull);
      });

      test('sets error on failure', () async {
        final mockGet = MockGetAssignments();
        final notifier = _buildNotifier(getAssignments: mockGet);

        when(() => mockGet(any(),
                publishedOnly: any(named: 'publishedOnly'),
                skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
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

        when(() => mockCreate(any())).thenAnswer((_) async =>
            Right(MutationResult(
                entity: tAssignment, status: SyncStatus.pending)));
        when(() => mockGet(any(),
                publishedOnly: any(named: 'publishedOnly'),
                skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
            .thenAnswer((_) async => Right([tAssignment]));

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
      test('sets successMessage on success', () async {
        final mockGet = MockGetAssignments();
        final mockDelete = MockDeleteAssignment();

        final notifier = _buildNotifier(
          getAssignments: mockGet,
          deleteAssignment: mockDelete,
        );

        when(() => mockGet(any(),
                publishedOnly: any(named: 'publishedOnly'),
                skipBackgroundRefresh: any(named: 'skipBackgroundRefresh')))
            .thenAnswer((_) async => Right([tAssignment]));
        await notifier.loadAssignments('c-1');

        when(() => mockDelete(any())).thenAnswer(
            (_) async => const Right(MutationResult(entity: null, status: SyncStatus.pending)));

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

    group('publishAssignment', () {
      test('sets successMessage on success', () async {
        final mockPublish = MockPublishAssignment();
        final notifier = _buildNotifier(publishAssignment: mockPublish);

        when(() => mockPublish(any())).thenAnswer((_) async =>
            Right(MutationResult(
                entity: tAssignment, status: SyncStatus.pending)));

        await notifier.publishAssignment('a-1');

        expect(notifier.state.successMessage, isNotNull);
        expect(notifier.state.error, isNull);
      });

      test('sets error on failure', () async {
        final mockPublish = MockPublishAssignment();
        final notifier = _buildNotifier(publishAssignment: mockPublish);

        when(() => mockPublish(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Publish failed')));

        await notifier.publishAssignment('a-1');

        expect(notifier.state.error, isNotNull);
      });
    });

    group('unpublishAssignment', () {
      test('sets successMessage on success', () async {
        final mockUnpublish = MockUnpublishAssignment();
        final notifier = _buildNotifier(unpublishAssignment: mockUnpublish);

        when(() => mockUnpublish(any())).thenAnswer((_) async =>
            Right(MutationResult(
                entity: tAssignment, status: SyncStatus.pending)));

        await notifier.unpublishAssignment('a-1');

        expect(notifier.state.successMessage, isNotNull);
        expect(notifier.state.error, isNull);
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

    group('clearMessages', () {
      test('clears error and successMessage', () {
        final notifier = _buildNotifier();
        notifier.state = notifier.state.copyWith(
          error: 'Some error',
          successMessage: 'Some success',
        );
        notifier.clearMessages();
        expect(notifier.state.error, isNull);
        expect(notifier.state.successMessage, isNull);
      });
    });
  });
}
