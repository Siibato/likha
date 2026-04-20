import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/data/repositories/tos/tos_repository_impl.dart';

import '../../../../helpers/mock_datasources.dart';
import '../../../../helpers/mock_repositories.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

TosModel _fakeTos({String id = 'tos-1', String classId = 'c-1'}) => TosModel(
      id: id,
      classId: classId,
      gradingPeriodNumber: 1,
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
  required MockServerReachabilityService reachability,
  bool isServerReachable = true,
}) {
  when(() => reachability.isServerReachable).thenReturn(isServerReachable);
  return TosRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    serverReachabilityService: reachability,
    syncQueue: syncQueue,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockTosLocalDataSource local;
  late MockTosRemoteDataSource remote;
  late MockSyncQueue syncQueue;
  late MockServerReachabilityService reachability;

  setUp(() {
    local = MockTosLocalDataSource();
    remote = MockTosRemoteDataSource();
    syncQueue = MockSyncQueue();
    reachability = MockServerReachabilityService();
    dotenv.testLoad(fileInput: '');

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

  group('TosRepositoryImpl', () {
    group('getTosList — cache hit', () {
      test('returns cached TOS list without hitting remote', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
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
          reachability: reachability,
          isServerReachable: true,
        );

        when(() => local.getTosByClass('c-1')).thenAnswer((_) async => []);
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
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          isServerReachable: false,
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

    group('createTos — offline', () {
      test('saves locally and enqueues sync op', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          isServerReachable: false,
        );

        when(() => local.saveTos(any())).thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.createTos(
          classId: 'c-1',
          data: {
            'title': 'Q1 TOS',
            'grading_period_number': 1,
            'classification_mode': 'difficulty',
            'total_items': 40,
          },
        );

        expect(result.isRight(), isTrue);
        verify(() => syncQueue.enqueue(any())).called(1);
        verifyNever(() => remote.createTos(
          classId: any(named: 'classId'),
          data: any(named: 'data'),
        ));
      });
    });

    group('createTos — online', () {
      test('calls remote and saves result locally', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          isServerReachable: true,
        );

        when(() => remote.createTos(
              classId: any(named: 'classId'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => _fakeTos());
        when(() => local.saveTos(any())).thenAnswer((_) async {});

        final result = await repo.createTos(
          classId: 'c-1',
          data: {
            'title': 'Q1 TOS',
            'grading_period_number': 1,
            'classification_mode': 'difficulty',
            'total_items': 40,
          },
        );

        expect(result.isRight(), isTrue);
        verify(() => remote.createTos(
          classId: any(named: 'classId'),
          data: any(named: 'data'),
        )).called(1);
        verify(() => local.saveTos(any())).called(1);
      });
    });

    group('error propagation', () {
      test('returns CacheFailure when local datasource throws', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
        );

        when(() => local.getTosByClass(any()))
            .thenThrow(Exception('DB error'));

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
