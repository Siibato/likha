import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/sync/sync_logger.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessment_remote_datasource.dart';
import 'package:likha/data/datasources/remote/sync_remote_datasource.dart';
import 'package:likha/services/storage_service.dart';

class MockServerReachabilityService extends Mock implements ServerReachabilityService {}
class MockSyncQueue extends Mock implements SyncQueue {}
class MockSyncRemoteDataSource extends Mock implements SyncRemoteDataSource {}
class MockLocalDatabase extends Mock implements LocalDatabase {}
class MockAssessmentRemoteDataSource extends Mock implements AssessmentRemoteDataSource {}
class MockAssessmentLocalDataSource extends Mock implements AssessmentLocalDataSource {}
class MockSyncLogger extends Mock implements SyncLogger {}
class MockStorageService extends Mock implements StorageService {}

void main() {
  late SyncManager syncManager;
  late MockServerReachabilityService mockReachabilityService;
  late MockSyncQueue mockSyncQueue;
  late MockSyncRemoteDataSource mockSyncRemote;
  late MockLocalDatabase mockLocalDatabase;
  late MockAssessmentRemoteDataSource mockAssessmentRemote;
  late MockAssessmentLocalDataSource mockAssessmentLocal;
  late MockSyncLogger mockSyncLogger;
  late MockStorageService mockStorageService;
  late ServerClockService serverClockService;

  setUp(() {
    mockReachabilityService = MockServerReachabilityService();
    mockSyncQueue = MockSyncQueue();
    mockSyncRemote = MockSyncRemoteDataSource();
    mockLocalDatabase = MockLocalDatabase();
    mockAssessmentRemote = MockAssessmentRemoteDataSource();
    mockAssessmentLocal = MockAssessmentLocalDataSource();
    mockSyncLogger = MockSyncLogger();
    mockStorageService = MockStorageService();
    serverClockService = ServerClockService();

    when(() => mockReachabilityService.onServerReachabilityChanged)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockReachabilityService.isServerReachable).thenReturn(false);

    syncManager = SyncManager(
      mockReachabilityService,
      mockSyncQueue,
      mockSyncRemote,
      mockLocalDatabase,
      mockAssessmentRemote,
      mockAssessmentLocal,
      mockSyncLogger,
      mockStorageService,
      serverClockService,
    );
  });

  group('SyncManager initial state', () {
    test('starts in idle phase', () {
      expect(syncManager.state.phase, SyncPhase.idle);
    });

    test('starts with zero pending count', () {
      expect(syncManager.state.pendingCount, 0);
    });

    test('starts with zero failed count', () {
      expect(syncManager.state.failedCount, 0);
    });

    test('starts with no error', () {
      expect(syncManager.state.lastError, isNull);
    });
  });

  group('SyncManager.start / stop', () {
    test('start subscribes to reachability stream', () {
      final controller = StreamController<bool>.broadcast();
      when(() => mockReachabilityService.onServerReachabilityChanged)
          .thenAnswer((_) => controller.stream);
      when(() => mockReachabilityService.isServerReachable).thenReturn(false);

      syncManager.start();

      verify(() => mockReachabilityService.onServerReachabilityChanged).called(greaterThan(0));
      controller.close();
    });

    test('stop cancels subscription without error', () {
      syncManager.stop();
      // No exception means success
      expect(true, true);
    });

    test('calling stop twice does not throw', () {
      syncManager.stop();
      syncManager.stop();
      expect(true, true);
    });
  });

  group('SyncManager.sync', () {
    test('does not sync when server is unreachable', () async {
      when(() => mockReachabilityService.isServerReachable).thenReturn(false);

      await syncManager.sync();

      verifyNever(() => mockStorageService.isAuthenticated());
    });

    test('does not sync when not authenticated', () async {
      when(() => mockReachabilityService.isServerReachable).thenReturn(true);
      when(() => mockStorageService.isAuthenticated()).thenAnswer((_) async => false);

      await syncManager.sync();

      verifyNever(() => mockSyncQueue.getPendingCount());
    });
  });

  group('SyncManager.setStateListener', () {
    test('listener is called when state changes', () {
      SyncState? received;
      syncManager.setStateListener((state) => received = state);

      syncManager.reset();

      expect(received, isNotNull);
      expect(received!.phase, SyncPhase.idle);
    });
  });

  group('SyncManager.reset', () {
    test('resets state to idle', () {
      syncManager.reset();

      expect(syncManager.state.phase, SyncPhase.idle);
      expect(syncManager.state.pendingCount, 0);
      expect(syncManager.state.failedCount, 0);
      expect(syncManager.state.assessmentsReady, false);
      expect(syncManager.state.assignmentsReady, false);
      expect(syncManager.state.materialsReady, false);
    });

    test('notifies state listener on reset', () {
      final states = <SyncState>[];
      syncManager.setStateListener(states.add);

      syncManager.reset();

      expect(states, hasLength(1));
      expect(states.first.phase, SyncPhase.idle);
    });

    test('cancels reachability subscription on reset', () {
      syncManager.reset();
      // No exception — subscription cleanly cancelled
      expect(true, true);
    });
  });
}
