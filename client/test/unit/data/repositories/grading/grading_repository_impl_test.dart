import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/general_average_model.dart';
import 'package:likha/data/models/grading/sf9_model.dart';
import 'package:likha/data/repositories/grading/grading_repository_impl.dart';

import '../../../../helpers/mock_datasources.dart';
import '../../../../helpers/mock_repositories.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

GradeItemModel _fakeItem({String id = 'gi-1', String classId = 'c-1'}) =>
    GradeItemModel(
      id: id,
      classId: classId,
      title: 'Long Quiz 1',
      component: 'written_work',
      gradingPeriodNumber: 1,
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
      gradingPeriodNumber: 1,
      wwWeight: 30.0,
      ptWeight: 50.0,
      qaWeight: 20.0,
      createdAt: DateTime(2024, 1, 1).toIso8601String(),
      updatedAt: DateTime(2024, 1, 1).toIso8601String(),
    );

GradingRepositoryImpl _buildRepo({
  required MockGradingLocalDataSource local,
  required MockGradingRemoteDataSource remote,
  required MockSyncQueue syncQueue,
  required MockServerReachabilityService reachability,
  MockDataEventBus? eventBus,
  bool isServerReachable = true,
}) {
  when(() => reachability.isServerReachable).thenReturn(isServerReachable);
  return GradingRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    serverReachabilityService: reachability,
    syncQueue: syncQueue,
    dataEventBus: eventBus ?? MockDataEventBus(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockGradingLocalDataSource local;
  late MockGradingRemoteDataSource remote;
  late MockSyncQueue syncQueue;
  late MockServerReachabilityService reachability;

  setUp(() {
    local = MockGradingLocalDataSource();
    remote = MockGradingRemoteDataSource();
    syncQueue = MockSyncQueue();
    reachability = MockServerReachabilityService();

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

  group('GradingRepositoryImpl', () {
    // ── getGradeItems ───────────────────────────────────────────────────

    group('getGradeItems — online', () {
      test('fetches from remote and saves to local when server reachable', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, isServerReachable: true,
        );

        when(() => remote.getGradeItems(
          classId: any(named: 'classId'),
          gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
          component: any(named: 'component'),
        )).thenAnswer((_) async => [_fakeItem()]);
        when(() => local.saveItems(any())).thenAnswer((_) async {});

        final result = await repo.getGradeItems(classId: 'c-1', gradingPeriodNumber: 1);

        expect(result.isRight(), isTrue);
        result.fold((f) => fail('Expected Right'), (list) => expect(list.length, 1));
        verify(() => remote.getGradeItems(
          classId: 'c-1',
          gradingPeriodNumber: 1,
          component: null,
        )).called(1);
        verify(() => local.saveItems(any())).called(1);
      });
    });

    group('getGradeItems — offline', () {
      test('reads from local cache when offline', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, isServerReachable: false,
        );

        when(() => local.getItemsByClassQuarter('c-1', 1, component: null))
            .thenAnswer((_) async => [_fakeItem()]);

        final result = await repo.getGradeItems(classId: 'c-1', gradingPeriodNumber: 1);

        expect(result.isRight(), isTrue);
        verifyNever(() => remote.getGradeItems(
          classId: any(named: 'classId'),
          gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
          component: any(named: 'component'),
        ));
      });
    });

    // ── saveScores ──────────────────────────────────────────────────────

    group('saveScores', () {
      test('saves locally and enqueues sync op', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability,
        );

        when(() => local.upsertScoresByItem(any(), any())).thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.saveScores(
          gradeItemId: 'gi-1',
          scores: [{'student_id': 's-1', 'score': 45.0}],
        );

        expect(result, const Right(null));
        verify(() => local.upsertScoresByItem('gi-1', any())).called(1);
        verify(() => syncQueue.enqueue(any())).called(1);
        verifyNever(() => remote.saveScores(
          gradeItemId: any(named: 'gradeItemId'),
          scores: any(named: 'scores'),
        ));
      });

      test('enqueues with correct entity type and operation', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability,
        );

        SyncQueueEntry? captured;
        when(() => local.upsertScoresByItem(any(), any())).thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((inv) async {
          captured = inv.positionalArguments[0] as SyncQueueEntry;
        });

        await repo.saveScores(
          gradeItemId: 'gi-2',
          scores: [{'student_id': 's-2', 'score': 90.0}],
        );

        expect(captured, isNotNull);
        expect(captured!.entityType, SyncEntityType.gradeScore);
        expect(captured!.operation, SyncOperation.saveScores);
        expect(captured!.payload['grade_item_id'], 'gi-2');
      });
    });

    // ── createGradeItem ─────────────────────────────────────────────────

    group('createGradeItem', () {
      test('saves locally and enqueues sync op', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability,
        );

        when(() => local.saveItem(any())).thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.createGradeItem(
          classId: 'c-1',
          data: {
            'title': 'LQ 1',
            'component': 'written_work',
            'total_points': 50.0,
            'grading_period_number': 1,
          },
        );

        expect(result.isRight(), isTrue);
        verify(() => local.saveItem(any())).called(1);
        verify(() => syncQueue.enqueue(any())).called(1);
      });
    });

    // ── deleteGradeItem ─────────────────────────────────────────────────

    group('deleteGradeItem', () {
      test('soft-deletes locally and enqueues delete op', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability,
        );

        when(() => local.softDeleteItem(any())).thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.deleteGradeItem(id: 'gi-1');

        expect(result, const Right(null));
        verify(() => local.softDeleteItem('gi-1')).called(1);
        verify(() => syncQueue.enqueue(any())).called(1);
      });
    });

    // ── getGradingConfig ────────────────────────────────────────────────

    group('getGradingConfig — online, non-empty', () {
      test('fetches from remote and caches locally', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, isServerReachable: true,
        );

        when(() => remote.getGradingConfig(classId: any(named: 'classId')))
            .thenAnswer((_) async => [_fakeConfig()]);
        when(() => local.saveConfigs(any())).thenAnswer((_) async {});

        final result = await repo.getGradingConfig(classId: 'c-1');

        expect(result.isRight(), isTrue);
        result.fold((f) => fail('Expected Right'), (list) => expect(list.isNotEmpty, isTrue));
        verify(() => local.saveConfigs(any())).called(1);
      });
    });

    group('getGradingConfig — offline', () {
      test('reads from local cache when offline', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, isServerReachable: false,
        );

        when(() => local.getConfigByClass('c-1')).thenAnswer((_) async => [_fakeConfig()]);

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
          reachability: reachability,
        );

        when(() => local.updateScoreOverride(any(), any())).thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.setScoreOverride(scoreId: 'sc-1', overrideScore: 95.0);

        expect(result, const Right(null));
        verify(() => local.updateScoreOverride('sc-1', 95.0)).called(1);
        verify(() => syncQueue.enqueue(any())).called(1);
      });
    });

    // ── getFinalGrades ──────────────────────────────────────────────────

    group('getFinalGrades — cache-first', () {
      test('returns cached data immediately and refreshes in background', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, isServerReachable: true,
        );

        when(() => local.getCachedFinalGrades('c-1'))
            .thenAnswer((_) async => [{'student_id': 's-1', 'finalGrade': 88}]);
        when(() => remote.getFinalGrades(classId: any(named: 'classId')))
            .thenAnswer((_) async => [{'student_id': 's-1', 'finalGrade': 90}]);
        when(() => local.cacheFinalGrades(any(), any())).thenAnswer((_) async {});

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
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, isServerReachable: true,
        );

        when(() => local.getCachedGeneralAverages('c-1'))
            .thenAnswer((_) async => {'class_id': 'c-1', 'students': []});
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
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, isServerReachable: true,
        );

        when(() => local.getCachedMyGradeDetail('c-1', 1))
            .thenAnswer((_) async => {'initial_grade': 88.5});
        when(() => remote.getMyGradeDetail(
          classId: any(named: 'classId'),
          gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
        )).thenAnswer((_) async => {'initial_grade': 88.5});

        final result = await repo.getMyGradeDetail(classId: 'c-1', gradingPeriodNumber: 1);

        expect(result.isRight(), isTrue);
      });
    });

    // ── getSf9 / getSf10 ────────────────────────────────────────────────

    group('getSf9 — cache-first', () {
      test('returns cached data immediately', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, isServerReachable: true,
        );

        when(() => local.getCachedSf9('c-1', 's-1'))
            .thenAnswer((_) async => {'student_id': 's-1', 'student_name': 'Student'});
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
