import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/data/repositories/tos/tos_repository_impl.dart';

import '../../../../helpers/mock_datasources.dart';
import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/test_database.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

TosModel _fakeTos({String id = 'tos-1', String classId = 'c-1'}) => TosModel(
      id: id,
      classId: classId,
      termNumber: 1,
      title: 'Q1 TOS',
      classificationMode: 'difficulty',
      totalItems: 40,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

TosRepositoryImpl _buildRepo({
  required MockTosLocalDataSource local,
  required MockTosRemoteDataSource remote,
  required MockSyncQueue syncQueue,
  MockDataEventBus? eventBus,
}) {
  return TosRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    syncQueue: syncQueue,
    dataEventBus: eventBus ?? MockDataEventBus(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockTosLocalDataSource local;
  late MockTosRemoteDataSource remote;
  late MockSyncQueue syncQueue;

  setUp(() {
    local = MockTosLocalDataSource();
    remote = MockTosRemoteDataSource();
    syncQueue = MockSyncQueue();
    dotenv.testLoad(fileInput: '');

    final reachability = MockServerReachabilityService();
    when(() => reachability.isServerReachable).thenReturn(true);
    when(() => reachability.checkNow()).thenAnswer((_) async => true);
    final getIt = GetIt.instance;
    if (getIt.isRegistered<ServerReachabilityService>()) {
      getIt.unregister<ServerReachabilityService>();
    }
    getIt.registerSingleton<ServerReachabilityService>(reachability);

    registerFallbackValue(_fakeTos());
    registerFallbackValue(SyncQueueEntry(
      id: 'fallback',
      entityType: SyncEntityType.tableOfSpecifications,
      operation: SyncOperation.create,
      payload: {},
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 3,
      createdAt: DateTime.now(),
    ));
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('TosRepositoryImpl', () {
    group('getTosList — cache hit', () {
      test('returns cached TOS list without hitting remote', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
        );

        when(() => local.getTosByClass('c-1'))
            .thenAnswer((_) async => [_fakeTos()]);

        final result = await repo.getTosList(classId: 'c-1');

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (list) => expect(list.length, 1),
        );
      });
    });

    group('getTosList — cache empty, online', () {
      test('fetches from remote and caches when cache empty and online', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
        );

        when(() => local.getTosByClass('c-1')).thenThrow(CacheException('empty'));
        when(() => remote.getTosByClass(classId: 'c-1'))
            .thenAnswer((_) async => [_fakeTos()]);
        when(() => local.cacheTosList(any())).thenAnswer((_) async {});

        final result = await repo.getTosList(classId: 'c-1');

        expect(result.isRight(), isTrue);
        verify(() => remote.getTosByClass(classId: 'c-1')).called(1);
        verify(() => local.cacheTosList(any())).called(1);
      });
    });

    group('getTosList — offline, empty cache', () {
      test('returns empty list when offline and nothing cached', () async {
        final getIt = GetIt.instance;
        final reachability = getIt<ServerReachabilityService>() as MockServerReachabilityService;
        when(() => reachability.isServerReachable).thenReturn(false);
        when(() => reachability.checkNow()).thenAnswer((_) async => false);

        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
        );

        when(() => local.getTosByClass('c-1')).thenAnswer((_) async => []);

        final result = await repo.getTosList(classId: 'c-1');

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (list) => expect(list, isEmpty),
        );
        verifyNever(() => remote.getTosByClass(classId: any(named: 'classId')));
      });
    });

    group('createTos', () {
      test('inserts locally, enqueues sync op, and returns MutationResult', () async {
        await openFreshTestDatabase();

        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
        );

        when(() => local.localDatabase).thenReturn(LocalDatabase());
        when(() => local.saveTos(any(), txn: any(named: 'txn')))
            .thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any(), txn: any(named: 'txn')))
            .thenAnswer((_) async {});
        when(() => remote.createTos(
          classId: any(named: 'classId'),
          data: any(named: 'data'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenThrow(NetworkException('offline'));

        final result = await repo.createTos(
          classId: 'c-1',
          data: {
            'title': 'Q1 TOS',
            'term_number': 1,
            'classification_mode': 'difficulty',
            'total_items': 40,
          },
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (mutationResult) {
            expect(mutationResult.entity.title, 'Q1 TOS');
            expect(mutationResult.status, SyncStatus.pending);
          },
        );
        verify(() => local.saveTos(any(), txn: any(named: 'txn'))).called(1);
        verify(() => syncQueue.enqueue(any(), txn: any(named: 'txn'))).called(1);
        verifyNever(() => remote.createTos(
          classId: any(named: 'classId'),
          data: any(named: 'data'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ));

        await closeTestDatabase();
      });
    });

    group('error propagation', () {
      test('returns CacheFailure when local datasource throws', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
        );

        when(() => local.getTosByClass(any()))
            .thenThrow(CacheException('DB error'));
        when(() => remote.getTosByClass(classId: any(named: 'classId')))
            .thenThrow(CacheException('remote cache miss'));

        final result = await repo.getTosList(classId: 'c-1');

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<CacheFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });
  });
}
