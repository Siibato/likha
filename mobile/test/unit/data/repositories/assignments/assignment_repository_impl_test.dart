import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/repositories/assignments/assignment_repository_impl.dart';

import '../../../../helpers/mock_datasources.dart';
import '../../../../helpers/mock_repositories.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

AssignmentModel _fakeModel({String id = 'a-1', String classId = 'c-1'}) =>
    AssignmentModel(
      id: id,
      classId: classId,
      title: 'Test Assignment',
      instructions: 'Do it',
      totalPoints: 100,
      allowsTextSubmission: false,
      allowsFileSubmission: false,
      dueAt: DateTime(2025, 6, 1),
      isPublished: true,
      orderIndex: 0,
      submissionCount: 0,
      gradedCount: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

AssignmentRepositoryImpl _buildRepo({
  required MockAssignmentLocalDataSource local,
  required MockAssignmentRemoteDataSource remote,
  required MockSyncQueue syncQueue,
  required MockServerReachabilityService reachability,
  required MockStorageService storage,
  required MockDataEventBus eventBus,
  bool isServerReachable = true,
}) {
  when(() => reachability.isServerReachable).thenReturn(isServerReachable);
  return AssignmentRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    validationService: MockValidationService(),
    connectivityService: MockConnectivityService(),
    syncQueue: syncQueue,
    serverReachabilityService: reachability,
    storageService: storage,
    dataEventBus: eventBus,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockAssignmentLocalDataSource local;
  late MockAssignmentRemoteDataSource remote;
  late MockSyncQueue syncQueue;
  late MockServerReachabilityService reachability;
  late MockStorageService storage;
  late MockDataEventBus eventBus;

  setUp(() {
    local = MockAssignmentLocalDataSource();
    remote = MockAssignmentRemoteDataSource();
    syncQueue = MockSyncQueue();
    reachability = MockServerReachabilityService();
    storage = MockStorageService();
    eventBus = MockDataEventBus();
    dotenv.testLoad(fileInput: '');
    when(() => storage.getUserId()).thenAnswer((_) async => null);
    when(() => storage.getUserRole()).thenAnswer((_) async => null);
    when(() => eventBus.onAssignmentsChanged).thenAnswer((_) => const Stream.empty());

    registerFallbackValue(_fakeModel());
    registerFallbackValue(SyncQueueEntry(
      id: 'fallback',
      entityType: SyncEntityType.assignment,
      operation: SyncOperation.create,
      payload: {},
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 5,
      createdAt: DateTime.now(),
    ));
  });

  group('AssignmentRepositoryImpl', () {
    group('getAssignments — online', () {
      test('fetches from remote and caches locally when server reachable', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: true,
        );

        when(() => local.getCachedAssignments(any(), publishedOnly: any(named: 'publishedOnly'), studentId: any(named: 'studentId')))
            .thenAnswer((_) async => [_fakeModel()]);
        when(() => remote.getAssignments(classId: any(named: 'classId')))
            .thenAnswer((_) async => [_fakeModel()]);
        when(() => local.cacheAssignments(any())).thenAnswer((_) async {});

        final result = await repo.getAssignments(classId: 'c-1', skipBackgroundRefresh: true);

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (list) => expect(list.length, 1),
        );
      });
    });

    group('getAssignments — offline', () {
      test('reads from local cache when server not reachable', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: false,
        );

        when(() => local.getCachedAssignments('c-1', publishedOnly: false, studentId: null))
            .thenAnswer((_) async => [_fakeModel()]);

        final result = await repo.getAssignments(classId: 'c-1');

        expect(result.isRight(), isTrue);
        verifyNever(() => remote.getAssignments(classId: any(named: 'classId')));
      });
    });

    group('createAssignment — offline', () {
      test('enqueues sync op and returns optimistic entity when offline', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: false,
        );

        when(() => local.cacheAssignments(any())).thenAnswer((_) async {});
        when(() => local.getCachedAssignments(any(), publishedOnly: any(named: 'publishedOnly'), studentId: any(named: 'studentId')))
            .thenAnswer((_) async => []);
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.createAssignment(
          classId: 'c-1',
          title: 'New',
          instructions: 'Do it',
          totalPoints: 50,
          allowsTextSubmission: true,
          allowsFileSubmission: false,
          dueAt: '2025-06-01T00:00:00',
        );

        expect(result.isRight(), isTrue);
        verify(() => syncQueue.enqueue(any())).called(1);
        verifyNever(() => remote.createAssignment(classId: any(named: 'classId'), data: any(named: 'data')));
      });
    });

    group('createAssignment — online', () {
      test('calls remote and caches locally when server reachable', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: true,
        );

        when(() => remote.createAssignment(
          classId: any(named: 'classId'),
          data: any(named: 'data'),
        )).thenAnswer((_) async => _fakeModel());
        when(() => local.cacheAssignmentDetail(any())).thenAnswer((_) async {});
        when(() => local.cacheAssignments(any())).thenAnswer((_) async {});
        when(() => local.getCachedAssignments(any(), publishedOnly: any(named: 'publishedOnly'), studentId: any(named: 'studentId')))
            .thenAnswer((_) async => [_fakeModel()]);

        final result = await repo.createAssignment(
          classId: 'c-1',
          title: 'New',
          instructions: 'Do it',
          totalPoints: 50,
          allowsTextSubmission: true,
          allowsFileSubmission: false,
          dueAt: '2025-06-01T00:00:00',
        );

        expect(result.isRight(), isTrue);
        verify(() => remote.createAssignment(
          classId: any(named: 'classId'),
          data: any(named: 'data'),
        )).called(1);
      });
    });

    group('deleteAssignment — offline', () {
      test('enqueues delete op when offline', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: false,
        );

        when(() => local.deleteAssignmentLocal(assignmentId: any(named: 'assignmentId')))
            .thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.deleteAssignment(assignmentId: 'a-1');

        expect(result, const Right(null));
        verify(() => syncQueue.enqueue(any())).called(1);
        verifyNever(() => remote.deleteAssignment(assignmentId: any(named: 'assignmentId')));
      });
    });

    group('error propagation', () {
      test('returns ServerFailure when remote throws and offline fallback also fails', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: true,
        );

        when(() => remote.getAssignments(classId: any(named: 'classId')))
            .thenThrow(ServerFailure('Network error'));
        when(() => local.getCachedAssignments(any(), publishedOnly: any(named: 'publishedOnly'), studentId: any(named: 'studentId')))
            .thenThrow(Exception('cache failure'));

        final result = await repo.getAssignments(classId: 'c-1');

        expect(result.isLeft(), isTrue);
      });
    });
  });
}
