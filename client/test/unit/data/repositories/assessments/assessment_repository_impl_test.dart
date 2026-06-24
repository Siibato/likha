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
}) {
  return AssessmentRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    validationService: MockValidationService(),
    connectivityService: MockConnectivityService(),
    syncQueue: syncQueue,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockAssessmentLocalDataSource local;
  late MockAssessmentRemoteDataSource remote;
  late MockSyncQueue syncQueue;

  setUp(() {
    local = MockAssessmentLocalDataSource();
    remote = MockAssessmentRemoteDataSource();
    syncQueue = MockSyncQueue();
    dotenv.testLoad(fileInput: '');

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
        );

        when(() => local.getCachedAssessments(any(), publishedOnly: any(named: 'publishedOnly')))
            .thenAnswer((_) async => [_fakeModel()]);
        when(() => remote.getAssessments(classId: any(named: 'classId')))
            .thenAnswer((_) async => [_fakeModel()]);
        when(() => local.cacheAssessments(any(), isServerConfirmed: any(named: 'isServerConfirmed'), txn: any(named: 'txn')))
            .thenAnswer((_) async {});

        final result = await repo.getAssessments(classId: 'c-1', skipBackgroundRefresh: true);

        expect(result.isRight(), isTrue);
      });
    });

    group('getAssessments — offline', () {
      test('reads from local cache when offline', () async {
        final repo = _buildRepo(
          local: local, remote: remote, syncQueue: syncQueue,
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
        // Skip: requires database transaction support which is difficult to mock
        // in unit tests. Covered by assessment_write_compliance_test.dart.
      }, skip: true);
    });

    group('createAssessment — online', () {
      test('creates locally and enqueues sync op (never calls remote)', () async {
        // Skip: requires database transaction support which is difficult to mock
        // in unit tests. Covered by assessment_write_compliance_test.dart.
      }, skip: true);
    });

    group('deleteAssessment — offline', () {
      test('deletes locally and enqueues sync op', () async {
        // Skip: requires database transaction support which is difficult to mock
        // in unit tests. Covered by assessment_write_compliance_test.dart.
      }, skip: true);
    });

    group('publishAssessment — offline', () {
      test('marks locally and enqueues publish op', () async {
        // Skip: requires database transaction support which is difficult to mock
        // in unit tests. Covered by assessment_write_compliance_test.dart.
      }, skip: true);
    });
  });
}
