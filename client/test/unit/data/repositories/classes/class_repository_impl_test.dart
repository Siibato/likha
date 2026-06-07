import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:likha/data/repositories/classes/class_repository_impl.dart';

import '../../../../helpers/mock_datasources.dart';
import '../../../../helpers/mock_repositories.dart';

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
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

ClassRepositoryImpl _buildRepo({
  required MockClassLocalDataSource local,
  required MockClassRemoteDataSource remote,
  required MockSyncQueue syncQueue,
  required MockServerReachabilityService reachability,
  required MockStorageService storage,
  required MockDataEventBus eventBus,
  bool isServerReachable = true,
}) {
  when(() => reachability.isServerReachable).thenReturn(isServerReachable);
  return ClassRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    validationService: MockValidationService(),
    serverReachabilityService: reachability,
    syncQueue: syncQueue,
    storageService: storage,
    dataEventBus: eventBus,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockClassLocalDataSource local;
  late MockClassRemoteDataSource remote;
  late MockSyncQueue syncQueue;
  late MockServerReachabilityService reachability;
  late MockStorageService storage;
  late MockDataEventBus eventBus;

  setUp(() {
    local = MockClassLocalDataSource();
    remote = MockClassRemoteDataSource();
    syncQueue = MockSyncQueue();
    reachability = MockServerReachabilityService();
    storage = MockStorageService();
    eventBus = MockDataEventBus();
    dotenv.testLoad(fileInput: '');
    when(() => storage.getUserId()).thenAnswer((_) async => 't-1');

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

  group('ClassRepositoryImpl', () {
    group('getAllClasses — cache hit', () {
      test('returns cached classes without hitting remote', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
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
          reachability: reachability,
          storage: storage,
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

    group('createClass — offline', () {
      test('enqueues sync op and returns optimistic entity', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: false,
        );

        when(() => local.getCachedClasses()).thenAnswer((_) async => []);
        when(() => local.cacheClasses(any())).thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.createClass(title: 'New Class');

        expect(result.isRight(), isTrue);
        verify(() => syncQueue.enqueue(any())).called(1);
        verifyNever(() => remote.createClass(
          title: any(named: 'title'),
          description: any(named: 'description'),
          teacherId: any(named: 'teacherId'),
          isAdvisory: any(named: 'isAdvisory'),
        ));
      });
    });

    group('createClass — online', () {
      test('calls remote and caches locally', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: true,
        );

        when(() => local.getCachedClasses()).thenAnswer((_) async => []);
        when(() => remote.createClass(
              title: any(named: 'title'),
              description: any(named: 'description'),
              teacherId: any(named: 'teacherId'),
              isAdvisory: any(named: 'isAdvisory'),
            )).thenAnswer((_) async => _fakeClass());
        when(() => local.cacheClasses(any())).thenAnswer((_) async {});

        final result = await repo.createClass(title: 'New Class');

        expect(result.isRight(), isTrue);
        verify(() => remote.createClass(
          title: any(named: 'title'),
          description: any(named: 'description'),
          teacherId: any(named: 'teacherId'),
          isAdvisory: any(named: 'isAdvisory'),
        )).called(1);
      });
    });

    group('error propagation', () {
      test('returns ServerFailure when remote throws ServerException', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: true,
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
