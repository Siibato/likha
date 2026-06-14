import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:likha/data/repositories/classes/class_repository_impl.dart';

import '../../../../helpers/mock_datasources.dart';
import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/test_database.dart';

import 'package:likha/core/database/local_database.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

ClassModel _fakeClass({String id = 'cl-1', String teacherId = 't-1'}) =>
    ClassModel(
      id: id,
      title: 'Math 101',
      teacherId: teacherId,
      teacherUsername: 'teacher1',
      teacherFullName: 'Teacher One',
      isArchived: false,
      studentCount: 0,
      gradingPeriodType: 'quarter',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      syncStatus: SyncStatus.synced,
    );

ClassRepositoryImpl _buildRepo({
  required MockClassLocalDataSource local,
  required MockClassRemoteDataSource remote,
  required MockSyncQueue syncQueue,
  required MockDataEventBus eventBus,
}) {
  return ClassRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    syncQueue: syncQueue,
    dataEventBus: eventBus,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockClassLocalDataSource local;
  late MockClassRemoteDataSource remote;
  late MockSyncQueue syncQueue;
  late MockDataEventBus eventBus;

  setUp(() {
    local = MockClassLocalDataSource();
    remote = MockClassRemoteDataSource();
    syncQueue = MockSyncQueue();
    eventBus = MockDataEventBus();
    dotenv.testLoad(fileInput: '');

    registerFallbackValue(_fakeClass());
    registerFallbackValue(SyncQueueEntry(
      id: 'fallback',
      entityType: SyncEntityType.classEntity,
      operation: SyncOperation.create,
      payload: {},
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 5,
      createdAt: DateTime.now(),
    ));
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('ClassRepositoryImpl', () {
    group('getAllClasses — cache hit', () {
      test('returns cached classes without hitting remote', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          eventBus: eventBus,
        );

        when(() => local.getCachedClasses())
            .thenAnswer((_) async => [_fakeClass()]);

        final result = await repo.getAllClasses(skipBackgroundRefresh: true);

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (list) => expect(list.length, 1),
        );
        verifyNever(() => remote.getAllClasses());
      });

      test('falls through to remote on CacheException', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          eventBus: eventBus,
        );

        when(() => local.getCachedClasses())
            .thenThrow(CacheException('cache miss'));
        when(() => remote.getAllClasses())
            .thenAnswer((_) async => [_fakeClass()]);
        when(() => local.cacheClasses(any())).thenAnswer((_) async {});

        final result = await repo.getAllClasses(skipBackgroundRefresh: true);

        expect(result.isRight(), isTrue);
        verify(() => remote.getAllClasses()).called(1);
      });
    });

    group('createClass', () {
      setUp(() async {
        await openFreshTestDatabase();
        when(() => local.localDatabase).thenReturn(LocalDatabase());
      });

      tearDown(() async {
        await closeTestDatabase();
      });

      test('inserts locally, enqueues sync op, and returns MutationResult', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          eventBus: eventBus,
        );

        when(() => local.insertClass(any(), txn: any(named: 'txn')))
            .thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any(), txn: any(named: 'txn')))
            .thenAnswer((_) async {});

        final result = await repo.createClass(title: 'New Class');

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (mutationResult) {
            expect(mutationResult.entity.title, 'New Class');
            expect(mutationResult.status, SyncStatus.pending);
          },
        );
        verify(() => local.insertClass(any(), txn: any(named: 'txn'))).called(1);
        verify(() => syncQueue.enqueue(any(), txn: any(named: 'txn'))).called(1);
        verifyNever(() => remote.createClass(
          title: any(named: 'title'),
          description: any(named: 'description'),
          teacherId: any(named: 'teacherId'),
          isAdvisory: any(named: 'isAdvisory'),
        ));
      });
    });

    group('error propagation', () {
      test('returns ServerFailure when remote throws ServerException', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          eventBus: eventBus,
        );

        when(() => local.getCachedClasses())
            .thenThrow(CacheException('miss'));
        when(() => remote.getAllClasses())
            .thenThrow(ServerException('Server down', statusCode: 500));

        final result = await repo.getAllClasses(skipBackgroundRefresh: true);

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });
  });
}
