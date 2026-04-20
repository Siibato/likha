import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/repositories/learning_materials/learning_material_repository_impl.dart';

import '../../../../helpers/mock_datasources.dart';
import '../../../../helpers/mock_repositories.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

LearningMaterialModel _fakeMaterial({
  String id = 'lm-1',
  String classId = 'c-1',
}) =>
    LearningMaterialModel(
      id: id,
      classId: classId,
      title: 'Lesson 1',
      orderIndex: 0,
      fileCount: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

LearningMaterialRepositoryImpl _buildRepo({
  required MockLearningMaterialLocalDataSource local,
  required MockLearningMaterialRemoteDataSource remote,
  required MockSyncQueue syncQueue,
  required MockServerReachabilityService reachability,
  required MockStorageService storage,
  required MockDataEventBus eventBus,
  bool isServerReachable = true,
}) {
  when(() => reachability.isServerReachable).thenReturn(isServerReachable);
  return LearningMaterialRepositoryImpl(
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
  late MockLearningMaterialLocalDataSource local;
  late MockLearningMaterialRemoteDataSource remote;
  late MockSyncQueue syncQueue;
  late MockServerReachabilityService reachability;
  late MockStorageService storage;
  late MockDataEventBus eventBus;

  setUp(() {
    local = MockLearningMaterialLocalDataSource();
    remote = MockLearningMaterialRemoteDataSource();
    syncQueue = MockSyncQueue();
    reachability = MockServerReachabilityService();
    storage = MockStorageService();
    eventBus = MockDataEventBus();
    dotenv.testLoad(fileInput: '');
    when(() => storage.getUserId()).thenAnswer((_) async => null);
    when(() => eventBus.onMaterialsChanged)
        .thenAnswer((_) => const Stream.empty());

    registerFallbackValue(_fakeMaterial());
    registerFallbackValue(SyncQueueEntry(
      id: 'fallback',
      entityType: SyncEntityType.learningMaterial,
      operation: SyncOperation.create,
      payload: {},
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 5,
      createdAt: DateTime.now(),
    ));
  });

  group('LearningMaterialRepositoryImpl', () {
    group('getMaterials — cache hit', () {
      test('returns cached materials without hitting remote', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: false,
        );

        when(() => local.getCachedMaterials('c-1'))
            .thenAnswer((_) async => [_fakeMaterial()]);

        final result = await repo.getMaterials(classId: 'c-1');

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (list) => expect(list.length, 1),
        );
        verifyNever(() => remote.getMaterials(classId: any(named: 'classId')));
      });
    });

    group('getMaterials — cache miss', () {
      test('fetches from remote and caches on CacheException', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: true,
        );

        when(() => local.getCachedMaterials('c-1'))
            .thenThrow(CacheException('empty'));
        when(() => remote.getMaterials(classId: 'c-1'))
            .thenAnswer((_) async => [_fakeMaterial()]);
        when(() => local.cacheMaterials(any())).thenAnswer((_) async {});

        final result = await repo.getMaterials(classId: 'c-1');

        expect(result.isRight(), isTrue);
        verify(() => remote.getMaterials(classId: 'c-1')).called(1);
        verify(() => local.cacheMaterials(any())).called(1);
      });

      test('returns NetworkFailure when remote throws NetworkException', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: true,
        );

        when(() => local.getCachedMaterials('c-1'))
            .thenThrow(CacheException('empty'));
        when(() => remote.getMaterials(classId: 'c-1'))
            .thenThrow(NetworkException('offline'));

        final result = await repo.getMaterials(classId: 'c-1');

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<NetworkFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('createMaterial — offline', () {
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

        when(() => local.getCachedMaterials(any()))
            .thenAnswer((_) async => []);
        when(() => local.cacheMaterials(any())).thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.createMaterial(
          classId: 'c-1',
          title: 'New Lesson',
        );

        expect(result.isRight(), isTrue);
        verify(() => syncQueue.enqueue(any())).called(1);
        verifyNever(() => remote.createMaterial(
          classId: any(named: 'classId'),
          data: any(named: 'data'),
        ));
      });
    });

    group('createMaterial — online', () {
      test('calls remote and caches result', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          eventBus: eventBus,
          isServerReachable: true,
        );

        when(() => remote.createMaterial(
              classId: any(named: 'classId'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => _fakeMaterial());
        when(() => local.getCachedMaterials(any()))
            .thenAnswer((_) async => []);
        when(() => local.cacheMaterials(any())).thenAnswer((_) async {});
        when(() => local.cacheMaterialDetail(any())).thenAnswer((_) async {});

        final result = await repo.createMaterial(
          classId: 'c-1',
          title: 'New Lesson',
        );

        expect(result.isRight(), isTrue);
        verify(() => remote.createMaterial(
          classId: any(named: 'classId'),
          data: any(named: 'data'),
        )).called(1);
      });
    });
  });
}
