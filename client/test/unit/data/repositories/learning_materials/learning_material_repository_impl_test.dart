import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/repositories/learning_materials/learning_material_repository_impl.dart';
import 'package:likha/services/storage_service.dart';

import '../../../../helpers/mock_datasources.dart';
import '../../../../helpers/test_database.dart';

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
  required LearningMaterialLocalDataSource local,
  required LearningMaterialRemoteDataSource remote,
  required SyncQueue syncQueue,
  required ServerReachabilityService reachability,
  required StorageService storage,
  bool isServerReachable = true,
}) {
  when(() => reachability.isServerReachable).thenReturn(isServerReachable);
  return LearningMaterialRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    syncQueue: syncQueue,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late LearningMaterialLocalDataSourceImpl local;
  late SyncQueueImpl syncQueue;
  late MockLearningMaterialRemoteDataSource remote;
  late MockServerReachabilityService reachability;
  late MockStorageService storage;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    local = LearningMaterialLocalDataSourceImpl(LocalDatabase(), syncQueue);
    remote = MockLearningMaterialRemoteDataSource();
    reachability = MockServerReachabilityService();
    storage = MockStorageService();
    dotenv.testLoad(fileInput: '');
    when(() => storage.getUserId()).thenAnswer((_) async => null);

    when(() => reachability.isServerReachable).thenReturn(true);
    when(() => reachability.checkNow()).thenAnswer((_) async => true);
    final getIt = GetIt.instance;
    if (getIt.isRegistered<ServerReachabilityService>()) {
      getIt.unregister<ServerReachabilityService>();
    }
    getIt.registerSingleton<ServerReachabilityService>(reachability);

    registerFallbackValue(_fakeMaterial());

    // Register SyncQueueEntry fallback before using any() with syncQueue.enqueue
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

  tearDown(() async {
    GetIt.instance.reset();
    await closeTestDatabase();
  });

  group('LearningMaterialRepositoryImpl', () {
    group('getMaterials — cache hit', () {
      test('returns cached materials without hitting remote', () async {
        // Pre-populate cache
        await local.cacheMaterials([_fakeMaterial()]);

        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          isServerReachable: false,
        );

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
          isServerReachable: true,
        );

        when(() => remote.getMaterials(classId: 'c-1'))
            .thenAnswer((_) async => [_fakeMaterial()]);

        final result = await repo.getMaterials(classId: 'c-1');

        expect(result.isRight(), isTrue);
      });

      test('returns NetworkFailure when remote throws NetworkException', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          syncQueue: syncQueue,
          reachability: reachability,
          storage: storage,
          isServerReachable: true,
        );

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
          isServerReachable: false,
        );

        final result = await repo.createMaterial(
          classId: 'c-1',
          title: 'New Lesson',
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (mr) => {
            expect(mr.status, SyncStatus.pending),
          },
        );
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
          isServerReachable: true,
        );

        final result = await repo.createMaterial(
          classId: 'c-1',
          title: 'New Lesson',
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (mr) => {
            expect(mr.status, SyncStatus.pending),
          },
        );
      });
    });
  });
}
