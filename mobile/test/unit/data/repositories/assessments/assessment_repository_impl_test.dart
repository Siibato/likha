import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_impl.dart';

import '../../../../helpers/mock_datasources.dart';
import '../../../../helpers/mock_repositories.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

AssessmentModel _fakeModel({String id = 'as-1', String classId = 'c-1'}) =>
    AssessmentModel(
      id: id,
      classId: classId,
      title: 'Quiz 1',
      timeLimitMinutes: 30,
      openAt: DateTime(2025, 6, 1),
      closeAt: DateTime(2025, 6, 2),
      showResultsImmediately: false,
      resultsReleased: false,
      isPublished: false,
      orderIndex: 0,
      totalPoints: 100,
      questionCount: 0,
      submissionCount: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

AssessmentRepositoryImpl _buildRepo({
  required MockAssessmentLocalDataSource local,
  required MockAssessmentRemoteDataSource remote,
  required MockSyncQueue syncQueue,
  required MockServerReachabilityService reachability,
  required MockStorageService storage,
  required MockDataEventBus eventBus,
  required MockSyncLogger syncLogger,
  bool isServerReachable = true,
}) {
  when(() => reachability.isServerReachable).thenReturn(isServerReachable);
  return AssessmentRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    validationService: MockValidationService(),
    connectivityService: MockConnectivityService(),
    syncQueue: syncQueue,
    serverReachabilityService: reachability,
    storageService: storage,
    dataEventBus: eventBus,
    syncLogger: syncLogger,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockAssessmentLocalDataSource local;
  late MockAssessmentRemoteDataSource remote;
  late MockSyncQueue syncQueue;
  late MockServerReachabilityService reachability;
  late MockStorageService storage;
  late MockDataEventBus eventBus;
  late MockSyncLogger syncLogger;

  setUp(() {
    local = MockAssessmentLocalDataSource();
    remote = MockAssessmentRemoteDataSource();
    syncQueue = MockSyncQueue();
    reachability = MockServerReachabilityService();
    storage = MockStorageService();
    eventBus = MockDataEventBus();
    syncLogger = MockSyncLogger();
    dotenv.testLoad(fileInput: '');
    when(() => storage.getUserId()).thenAnswer((_) async => null);
    when(() => eventBus.onAssessmentsChanged).thenAnswer((_) => const Stream.empty());

    registerFallbackValue(SyncQueueEntry(
      id: 'fallback',
      entityType: SyncEntityType.assessment,
      operation: SyncOperation.create,
      payload: {},
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 5,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(<QuestionModel>[]);
    registerFallbackValue(_fakeModel());
  });

  group('AssessmentRepositoryImpl', () {
    group('getAssessments — online', () {
      test('fetches from remote and caches locally', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, storage: storage,
          eventBus: eventBus, syncLogger: syncLogger, isServerReachable: true,
        );

        when(() => local.getCachedAssessments(any(), publishedOnly: any(named: 'publishedOnly')))
            .thenAnswer((_) async => [_fakeModel()]);
        when(() => remote.getAssessments(classId: any(named: 'classId')))
            .thenAnswer((_) async => [_fakeModel()]);
        when(() => local.cacheAssessments(any())).thenAnswer((_) async {});

        final result = await repo.getAssessments(classId: 'c-1', skipBackgroundRefresh: true);

        expect(result.isRight(), isTrue);
      });
    });

    group('getAssessments — offline', () {
      test('reads from local cache when offline', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, storage: storage,
          eventBus: eventBus, syncLogger: syncLogger, isServerReachable: false,
        );

        when(() => local.getCachedAssessments(any(), publishedOnly: any(named: 'publishedOnly')))
            .thenAnswer((_) async => [_fakeModel()]);

        final result = await repo.getAssessments(classId: 'c-1', skipBackgroundRefresh: true);

        expect(result.isRight(), isTrue);
        verifyNever(() => remote.getAssessments(classId: any(named: 'classId')));
      });
    });

    group('createAssessment — offline', () {
      test('creates locally and enqueues sync op', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, storage: storage,
          eventBus: eventBus, syncLogger: syncLogger, isServerReachable: false,
        );

        when(() => local.createAssessmentLocally(
          classId: any(named: 'classId'),
          title: any(named: 'title'),
          timeLimitMinutes: any(named: 'timeLimitMinutes'),
          openAt: any(named: 'openAt'),
          closeAt: any(named: 'closeAt'),
          description: any(named: 'description'),
          showResultsImmediately: any(named: 'showResultsImmediately'),
          isPublished: any(named: 'isPublished'),
          tosId: any(named: 'tosId'),
          gradingPeriodNumber: any(named: 'gradingPeriodNumber'),
          component: any(named: 'component'),
        )).thenAnswer((_) async => 'as-new');
        when(() => local.getCachedAssessments(any(), publishedOnly: any(named: 'publishedOnly')))
            .thenAnswer((_) async => []);
        when(() => local.cacheAssessments(any())).thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.createAssessment(
          classId: 'c-1',
          title: 'Quiz 1',
          timeLimitMinutes: 30,
          openAt: '2025-06-01T08:00:00',
          closeAt: '2025-06-01T09:00:00',
        );

        expect(result.isRight(), isTrue);
        verifyNever(() => remote.createAssessment(classId: any(named: 'classId'), data: any(named: 'data')));
      });
    });

    group('createAssessment — online', () {
      test('calls remote and caches locally when server reachable', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, storage: storage,
          eventBus: eventBus, syncLogger: syncLogger, isServerReachable: true,
        );

        when(() => remote.createAssessment(
          classId: any(named: 'classId'),
          data: any(named: 'data'),
        )).thenAnswer((_) async => _fakeModel());
        when(() => local.cacheAssessmentDetail(any(), any())).thenAnswer((_) async {});
        when(() => local.getCachedAssessments(any(), publishedOnly: any(named: 'publishedOnly')))
            .thenAnswer((_) async => [_fakeModel()]);
        when(() => local.cacheAssessments(any())).thenAnswer((_) async {});

        final result = await repo.createAssessment(
          classId: 'c-1',
          title: 'Quiz 1',
          timeLimitMinutes: 30,
          openAt: '2025-06-01T08:00:00',
          closeAt: '2025-06-01T09:00:00',
        );

        expect(result.isRight(), isTrue);
        verify(() => remote.createAssessment(
          classId: any(named: 'classId'),
          data: any(named: 'data'),
        )).called(1);
      });
    });

    group('deleteAssessment — offline', () {
      test('deletes locally and enqueues sync op', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, storage: storage,
          eventBus: eventBus, syncLogger: syncLogger, isServerReachable: false,
        );

        when(() => local.deleteAssessmentLocally(assessmentId: any(named: 'assessmentId')))
            .thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.deleteAssessment(assessmentId: 'as-1');

        expect(result.isRight(), isTrue);
        verify(() => local.deleteAssessmentLocally(assessmentId: 'as-1')).called(1);
        verify(() => syncQueue.enqueue(any())).called(1);
      });
    });

    group('publishAssessment — offline', () {
      test('marks locally and enqueues publish op', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
          reachability: reachability, storage: storage,
          eventBus: eventBus, syncLogger: syncLogger, isServerReachable: false,
        );

        const fakeQ = QuestionModel(
          id: 'q-1', assessmentId: 'as-1', questionText: 'Q?',
          questionType: 'multiple_choice', points: 1, orderIndex: 0,
          isMultiSelect: false,
        );
        when(() => local.getCachedAssessmentDetail(any()))
            .thenAnswer((_) async => (_fakeModel(), [fakeQ]));
        when(() => local.markAssessmentPublishedLocally(assessmentId: any(named: 'assessmentId')))
            .thenAnswer((_) async {});
        when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});

        final result = await repo.publishAssessment(assessmentId: 'as-1');

        expect(result.isRight(), isTrue);
        verify(() => local.markAssessmentPublishedLocally(assessmentId: 'as-1')).called(1);
        verify(() => syncQueue.enqueue(any())).called(1);
      });
    });
  });
}
