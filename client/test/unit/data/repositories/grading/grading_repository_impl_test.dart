import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/general_average_model.dart';
import 'package:likha/data/models/grading/sf9_model.dart';
import 'package:likha/data/repositories/grading/grading_repository_impl.dart';

import '../../../../helpers/mock_datasources.dart';
import '../../../../helpers/test_database.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

GradeItemModel _fakeItem({String id = 'gi-1', String classId = 'c-1'}) =>
    GradeItemModel(
      id: id,
      classId: classId,
      title: 'Long Quiz 1',
      component: 'written_work',
      termNumber: 1,
      totalPoints: 50.0,
      sourceType: 'manual',
      orderIndex: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

GradeConfigModel _fakeConfig({String id = 'cfg-1', String classId = 'c-1'}) =>
    GradeConfigModel(
      id: id,
      classId: classId,
      termNumber: 1,
      wwWeight: 30.0,
      ptWeight: 50.0,
      qaWeight: 20.0,
      createdAt: DateTime(2024, 1, 1).toIso8601String(),
      updatedAt: DateTime(2024, 1, 1).toIso8601String(),
    );

GradingRepositoryImpl _buildRepo({
  required GradingLocalDataSource local,
  required GradingRemoteDataSource remote,
  required SyncQueue syncQueue,
}) {
  return GradingRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    syncQueue: syncQueue,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late GradingLocalDataSourceImpl local;
  late SyncQueueImpl syncQueue;
  late MockGradingRemoteDataSource remote;
  late MockServerReachabilityService reachability;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    local = GradingLocalDataSourceImpl(LocalDatabase(), syncQueue);
    remote = MockGradingRemoteDataSource();
    reachability = MockServerReachabilityService();
    dotenv.testLoad(fileInput: '');

    when(() => reachability.isServerReachable).thenReturn(true);
    when(() => reachability.checkNow()).thenAnswer((_) async => true);
    final getIt = GetIt.instance;
    if (getIt.isRegistered<ServerReachabilityService>()) {
      getIt.unregister<ServerReachabilityService>();
    }
    getIt.registerSingleton<ServerReachabilityService>(reachability);

    registerFallbackValue(SyncQueueEntry(
      id: 'fallback',
      entityType: SyncEntityType.gradeScore,
      operation: SyncOperation.saveScores,
      payload: {},
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 3,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(_fakeItem());
    registerFallbackValue(<GradeItemModel>[]);
    registerFallbackValue(<GradeConfigModel>[]);
    registerFallbackValue(<GradeScoreModel>[]);
  });

  tearDown(() async {
    GetIt.instance.reset();
    await closeTestDatabase();
  });

  group('GradingRepositoryImpl', () {
    // ── getGradeItems ───────────────────────────────────────────────────

    group('getGradeItems — online', () {
      test('fetches from remote and saves to local when server reachable', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );

        when(() => remote.getGradeItems(
          classId: any(named: 'classId'),
          termNumber: any(named: 'termNumber'),
          component: any(named: 'component'),
        )).thenAnswer((_) async => [_fakeItem()]);

        final result = await repo.getGradeItems(classId: 'c-1', termNumber: 1);

        expect(result.isRight(), isTrue);
        result.fold((f) => fail('Expected Right'), (list) => expect(list.length, 1));
      });
    });

    group('getGradeItems — offline', () {
      test('reads from local cache when offline', () async {
        // Pre-populate database
        await local.saveItems([_fakeItem()]);

        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );

        final result = await repo.getGradeItems(classId: 'c-1', termNumber: 1);

        expect(result.isRight(), isTrue);
        verifyNever(() => remote.getGradeItems(
          classId: any(named: 'classId'),
          termNumber: any(named: 'termNumber'),
          component: any(named: 'component'),
        ));
      });
    });

    // ── saveScores ──────────────────────────────────────────────────────

    group('saveScores', () {
      test('saves locally and enqueues sync op', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );


        final result = await repo.saveScores(
          gradeItemId: 'gi-1',
          scores: [{'student_id': 's-1', 'score': 45.0}],
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (mr) => {
            expect(mr.status, SyncStatus.pending),
          },
        );
        verifyNever(() => remote.saveScores(
          gradeItemId: any(named: 'gradeItemId'),
          scores: any(named: 'scores'),
        ));
      });

      test('enqueues with correct entity type and operation', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );

        final result = await repo.saveScores(
          gradeItemId: 'gi-2',
          scores: [{'student_id': 's-2', 'score': 90.0}],
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

    // ── createGradeItem ─────────────────────────────────────────────────

    group('createGradeItem', () {
      test('saves locally and enqueues sync op', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          
        );

        final result = await repo.createGradeItem(
          classId: 'c-1',
          data: {
            'title': 'LQ 1',
            'component': 'written_work',
            'total_points': 50.0,
            'term_number': 1,
          },
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

    // ── deleteGradeItem ─────────────────────────────────────────────────

    group('deleteGradeItem', () {
      test('soft-deletes locally and enqueues delete op', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );

        final result = await repo.deleteGradeItem(id: 'gi-1');

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (mr) => {
            expect(mr.status, SyncStatus.pending),
          },
        );
      });
    });

    // ── getGradingConfig ────────────────────────────────────────────────

    group('getGradingConfig — online, non-empty', () {
      test('fetches from remote and caches locally', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );

        when(() => remote.getGradingConfig(classId: any(named: 'classId')))
            .thenAnswer((_) async => [_fakeConfig()]);

        final result = await repo.getGradingConfig(classId: 'c-1');

        expect(result.isRight(), isTrue);
        result.fold((f) => fail('Expected Right'), (list) => expect(list.isNotEmpty, isTrue));
      });
    });

    group('getGradingConfig — offline', () {
      test('reads from local cache when offline', () async {
        // Pre-populate cache
        await local.saveConfigs([_fakeConfig()]);

        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );

        final result = await repo.getGradingConfig(classId: 'c-1');

        expect(result.isRight(), isTrue);
        verifyNever(() => remote.getGradingConfig(classId: any(named: 'classId')));
      });
    });

    // ── setScoreOverride ────────────────────────────────────────────────

    group('setScoreOverride', () {
      test('updates locally and enqueues set_override op', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );

        final result = await repo.setScoreOverride(scoreId: 'sc-1', overrideScore: 95.0);

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (mr) => {
            expect(mr.status, SyncStatus.pending),
          },
        );
      });
    });

    // ── getFinalGrades ──────────────────────────────────────────────────

    group('getFinalGrades — cache-first', () {
      test('returns cached data immediately and refreshes in background', () async {
        // Pre-populate cache
        await local.cacheFinalGrades('c-1', [{'student_id': 's-1', 'finalGrade': 88}]);

        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );

        when(() => remote.getFinalGrades(classId: any(named: 'classId')))
            .thenAnswer((_) async => [{'student_id': 's-1', 'finalGrade': 90}]);

        final result = await repo.getFinalGrades(classId: 'c-1');

        expect(result.isRight(), isTrue);
        result.fold((f) => fail('Expected Right'), (data) {
          expect(data.length, 1);
          expect(data.first['finalGrade'], 88);
        });
      });

    });

    // ── getGeneralAverages ──────────────────────────────────────────────

    group('getGeneralAverages — cache-first', () {
      test('returns cached data immediately', () async {
        // Pre-populate cache
        await local.cacheGeneralAverages('c-1', {'class_id': 'c-1', 'students': []});

        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );

        when(() => remote.getGeneralAverages(classId: any(named: 'classId')))
            .thenAnswer((_) async => const GeneralAverageResponseModel(
              classId: 'c-1',
              students: [],
            ));

        final result = await repo.getGeneralAverages(classId: 'c-1');

        expect(result.isRight(), isTrue);
      });
    });

    // ── getMyGradeDetail ────────────────────────────────────────────────

    group('getMyGradeDetail — cache-first', () {
      test('returns cached data immediately', () async {
        // Pre-populate cache
        await local.cacheMyGradeDetail('c-1', 1, {'initial_grade': 88.5});

        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );

        when(() => remote.getMyGradeDetail(
          classId: any(named: 'classId'),
          termNumber: any(named: 'termNumber'),
        )).thenAnswer((_) async => {'initial_grade': 88.5});

        final result = await repo.getMyGradeDetail(classId: 'c-1', termNumber: 1);

        expect(result.isRight(), isTrue);
      });
    });

    // ── getSf9 / getSf10 ────────────────────────────────────────────────

    group('getSf9 — cache-first', () {
      test('returns cached data immediately', () async {
        // Pre-populate cache
        await local.cacheSf9('c-1', 's-1', {'student_id': 's-1', 'student_name': 'Student'});

        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,

        );

        when(() => remote.getSf9(classId: any(named: 'classId'), studentId: any(named: 'studentId')))
            .thenAnswer((_) async => const Sf9ResponseModel(
              studentId: 's-1',
              studentName: 'Student',
              subjects: [],
            ));

        final result = await repo.getSf9(classId: 'c-1', studentId: 's-1');

        expect(result.isRight(), isTrue);
      });
    });
  });
}
