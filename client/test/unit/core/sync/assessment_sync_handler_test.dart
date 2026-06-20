import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/outbound_sync_handler.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_state.dart';
import 'package:likha/data/datasources/remote/sync/sync_remote_datasource.dart';
import 'package:likha/data/models/sync/push_response_model.dart';

import '../../../helpers/mock_datasources.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_database.dart';

class MockSyncRemoteDataSource extends Mock implements SyncRemoteDataSource {}

void main() {
  late OutboundSyncHandler handler;
  late MockSyncQueue mockSyncQueue;
  late MockSyncRemoteDataSource mockSyncRemote;
  late MockSyncLogger mockSyncLogger;

  setUp(() async {
    await openFreshTestDatabase();
    mockSyncQueue = MockSyncQueue();
    mockSyncRemote = MockSyncRemoteDataSource();
    mockSyncLogger = MockSyncLogger();
    handler = OutboundSyncHandler(
      mockSyncQueue,
      mockSyncRemote,
      LocalDatabase(),
      mockSyncLogger,
      ({SyncPhase? phase, int? pendingCount, int? failedCount, String? lastError, DateTime? lastSyncAt, double? progress, String? currentStep, bool? assessmentsReady, bool? assignmentsReady, bool? materialsReady}) {},
    );

    when(() => mockSyncQueue.getById(any())).thenAnswer((_) async => null);
    when(() => mockSyncQueue.markSucceeded(any())).thenAnswer((_) async {});
    when(() => mockSyncQueue.markFailed(any(), any())).thenAnswer((_) async {});

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
  });

  tearDown(() async {
    await closeTestDatabase();
  });

  group('Assessment sync – idempotency key', () {
    test('sends entry.id as idempotency key in operations list', () async {
      final entry = SyncQueueEntry(
        id: 'entry-1',
        entityType: SyncEntityType.assessment,
        operation: SyncOperation.create,
        payload: {'id': 'assessment-1'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      );

      when(() => mockSyncRemote.pushOperations(operations: any(named: 'operations')))
          .thenAnswer((_) async => PushResponseModel(results: []));

      await handler.syncRegularBatch([entry], DateTime.now());

      final captured = verify(() => mockSyncRemote.pushOperations(
        operations: captureAny(named: 'operations'),
      )).captured;
      final operations = captured.first as List<Map<String, dynamic>>;
      expect(operations.length, 1);
      expect(operations.first['id'], 'entry-1');
      expect(operations.first['entity_type'], 'assessment');
      expect(operations.first['operation'], 'create');
    });
  });

  group('Assessment sync – success reconciliation', () {
    test('updates local DB sync_status to synced and marks queue entry succeeded', () async {
      final db = await LocalDatabase().database;
      await db.insert(DbTables.assessments, {
        CommonCols.id: 'assessment-1',
        AssessmentsCols.classId: 'class-1',
        AssessmentsCols.title: 'Test',
        AssessmentsCols.timeLimitMinutes: 60,
        AssessmentsCols.openAt: DateTime(2025, 1, 1).toIso8601String(),
        AssessmentsCols.closeAt: DateTime(2025, 12, 31).toIso8601String(),
        AssessmentsCols.showResultsImmediately: 0,
        AssessmentsCols.resultsReleased: 0,
        AssessmentsCols.isPublished: 0,
        AssessmentsCols.orderIndex: 0,
        AssessmentsCols.totalPoints: 100,
        AssessmentsCols.questionCount: 0,
        AssessmentsCols.submissionCount: 0,
        CommonCols.createdAt: DateTime.now().toIso8601String(),
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
        CommonCols.syncStatus: SyncStatus.pending.dbValue,
      });

      final entry = SyncQueueEntry(
        id: 'entry-1',
        entityType: SyncEntityType.assessment,
        operation: SyncOperation.create,
        payload: {CommonCols.id: 'assessment-1'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      );

      when(() => mockSyncQueue.getById('entry-1')).thenAnswer((_) async => entry);
      when(() => mockSyncQueue.markSucceeded(any())).thenAnswer((_) async {});
      when(() => mockSyncQueue.markFailed(any(), any())).thenAnswer((_) async {});

      final response = PushResponseModel(
        results: [
          OperationResultModel(
            id: 'entry-1',
            entityType: 'assessment',
            operation: 'create',
            success: true,
          ),
        ],
      );

      await handler.processPushResults(response, DateTime.now());

      final rows = await db.query(
        DbTables.assessments,
        where: '${CommonCols.id} = ?',
        whereArgs: ['assessment-1'],
      );
      expect(rows.first[CommonCols.syncStatus], SyncStatus.synced.dbValue);

      verify(() => mockSyncQueue.markSucceeded('entry-1')).called(1);
      verifyNever(() => mockSyncQueue.markFailed(any(), any()));
    });
  });

  group('Assessment sync – failure reconciliation', () {
    test('updates local DB sync_status to failed and marks queue entry failed', () async {
      final db = await LocalDatabase().database;
      await db.insert(DbTables.assessments, {
        CommonCols.id: 'assessment-1',
        AssessmentsCols.classId: 'class-1',
        AssessmentsCols.title: 'Test',
        AssessmentsCols.timeLimitMinutes: 60,
        AssessmentsCols.openAt: DateTime(2025, 1, 1).toIso8601String(),
        AssessmentsCols.closeAt: DateTime(2025, 12, 31).toIso8601String(),
        AssessmentsCols.showResultsImmediately: 0,
        AssessmentsCols.resultsReleased: 0,
        AssessmentsCols.isPublished: 0,
        AssessmentsCols.orderIndex: 0,
        AssessmentsCols.totalPoints: 100,
        AssessmentsCols.questionCount: 0,
        AssessmentsCols.submissionCount: 0,
        CommonCols.createdAt: DateTime.now().toIso8601String(),
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
        CommonCols.syncStatus: SyncStatus.pending.dbValue,
      });

      final entry = SyncQueueEntry(
        id: 'entry-1',
        entityType: SyncEntityType.assessment,
        operation: SyncOperation.create,
        payload: {CommonCols.id: 'assessment-1'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      );

      when(() => mockSyncQueue.getById('entry-1')).thenAnswer((_) async => entry);
      when(() => mockSyncQueue.markSucceeded(any())).thenAnswer((_) async {});
      when(() => mockSyncQueue.markFailed(any(), any())).thenAnswer((_) async {});

      final response = PushResponseModel(
        results: [
          OperationResultModel(
            id: 'entry-1',
            entityType: 'assessment',
            operation: 'create',
            success: false,
            error: 'Validation failed',
          ),
        ],
      );

      await handler.processPushResults(response, DateTime.now());

      final rows = await db.query(
        DbTables.assessments,
        where: '${CommonCols.id} = ?',
        whereArgs: ['assessment-1'],
      );
      expect(rows.first[CommonCols.syncStatus], SyncStatus.failed.dbValue);

      verify(() => mockSyncQueue.markFailed('entry-1', 'Validation failed')).called(1);
      verifyNever(() => mockSyncQueue.markSucceeded(any()));
    });
  });

  group('Assessment sync – retry on NetworkException', () {
    test('leaves queue entry pending when remote call throws NetworkException', () async {
      final entry = SyncQueueEntry(
        id: 'entry-1',
        entityType: SyncEntityType.assessment,
        operation: SyncOperation.create,
        payload: {CommonCols.id: 'assessment-1'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      );

      when(() => mockSyncRemote.pushOperations(operations: any(named: 'operations')))
          .thenThrow(NetworkException('Timeout'));

      expect(
        () => handler.syncRegularBatch([entry], DateTime.now()),
        throwsA(isA<NetworkException>()),
      );

      verifyNever(() => mockSyncQueue.markSucceeded(any()));
      verifyNever(() => mockSyncQueue.markFailed(any(), any()));
    });
  });

  group('Admin user sync – idempotency key', () {
    test('sends entry.id as idempotency key in operations list', () async {
      final entry = SyncQueueEntry(
        id: 'entry-admin-1',
        entityType: SyncEntityType.adminUser,
        operation: SyncOperation.create,
        payload: {'id': 'user-1', 'username': 'testuser', 'full_name': 'Test User', 'role': 'student'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      );

      when(() => mockSyncRemote.pushOperations(operations: any(named: 'operations')))
          .thenAnswer((_) async => PushResponseModel(results: []));

      await handler.syncRegularBatch([entry], DateTime.now());

      final captured = verify(() => mockSyncRemote.pushOperations(
        operations: captureAny(named: 'operations'),
      )).captured;
      final operations = captured.first as List<Map<String, dynamic>>;
      expect(operations.length, 1);
      expect(operations.first['id'], 'entry-admin-1');
      expect(operations.first['entity_type'], 'admin_user');
      expect(operations.first['operation'], 'create');
    });
  });

  group('Admin user sync – success reconciliation', () {
    test('updates local DB sync_status to synced and marks queue entry succeeded', () async {
      final db = await LocalDatabase().database;
      await db.insert(DbTables.users, {
        CommonCols.id: 'user-1',
        UsersCols.username: 'testuser',
        UsersCols.fullName: 'Test User',
        UsersCols.role: 'student',
        UsersCols.accountStatus: 'active',
        CommonCols.createdAt: DateTime.now().toIso8601String(),
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
        CommonCols.syncStatus: SyncStatus.pending.dbValue,
      });

      final entry = SyncQueueEntry(
        id: 'entry-admin-1',
        entityType: SyncEntityType.adminUser,
        operation: SyncOperation.create,
        payload: {CommonCols.id: 'user-1'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      );

      when(() => mockSyncQueue.getById('entry-admin-1')).thenAnswer((_) async => entry);
      when(() => mockSyncQueue.markSucceeded(any())).thenAnswer((_) async {});
      when(() => mockSyncQueue.markFailed(any(), any())).thenAnswer((_) async {});

      final response = PushResponseModel(
        results: [
          OperationResultModel(
            id: 'entry-admin-1',
            entityType: 'admin_user',
            operation: 'create',
            success: true,
          ),
        ],
      );

      await handler.processPushResults(response, DateTime.now());

      final rows = await db.query(
        DbTables.users,
        where: '${CommonCols.id} = ?',
        whereArgs: ['user-1'],
      );
      expect(rows.first[CommonCols.syncStatus], SyncStatus.synced.dbValue);

      verify(() => mockSyncQueue.markSucceeded('entry-admin-1')).called(1);
      verifyNever(() => mockSyncQueue.markFailed(any(), any()));
    });
  });

  group('Admin user sync – failure reconciliation', () {
    test('updates local DB sync_status to failed and marks queue entry failed', () async {
      final db = await LocalDatabase().database;
      await db.insert(DbTables.users, {
        CommonCols.id: 'user-1',
        UsersCols.username: 'testuser',
        UsersCols.fullName: 'Test User',
        UsersCols.role: 'student',
        UsersCols.accountStatus: 'active',
        CommonCols.createdAt: DateTime.now().toIso8601String(),
        CommonCols.updatedAt: DateTime.now().toIso8601String(),
        CommonCols.syncStatus: SyncStatus.pending.dbValue,
      });

      final entry = SyncQueueEntry(
        id: 'entry-admin-1',
        entityType: SyncEntityType.adminUser,
        operation: SyncOperation.create,
        payload: {CommonCols.id: 'user-1'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 5,
        createdAt: DateTime.now(),
      );

      when(() => mockSyncQueue.getById('entry-admin-1')).thenAnswer((_) async => entry);
      when(() => mockSyncQueue.markSucceeded(any())).thenAnswer((_) async {});
      when(() => mockSyncQueue.markFailed(any(), any())).thenAnswer((_) async {});

      final response = PushResponseModel(
        results: [
          OperationResultModel(
            id: 'entry-admin-1',
            entityType: 'admin_user',
            operation: 'create',
            success: false,
            error: 'Validation failed',
          ),
        ],
      );

      await handler.processPushResults(response, DateTime.now());

      final rows = await db.query(
        DbTables.users,
        where: '${CommonCols.id} = ?',
        whereArgs: ['user-1'],
      );
      expect(rows.first[CommonCols.syncStatus], SyncStatus.failed.dbValue);

      verify(() => mockSyncQueue.markFailed('entry-admin-1', 'Validation failed')).called(1);
      verifyNever(() => mockSyncQueue.markSucceeded(any()));
    });
  });

  group('Assessment sync – all operation variants', () {
    final operations = [
      (SyncOperation.create, 'create'),
      (SyncOperation.update, 'update'),
      (SyncOperation.delete, 'delete'),
      (SyncOperation.publish, 'publish'),
      (SyncOperation.unpublish, 'unpublish'),
      (SyncOperation.submit, 'submit'),
      (SyncOperation.saveAnswers, 'save_answers'),
      (SyncOperation.releaseResults, 'release_results'),
      (SyncOperation.overrideAnswer, 'override_answer'),
      (SyncOperation.gradeEssay, 'grade_essay'),
    ];

    for (final (syncOp, serverOp) in operations) {
      test('maps $syncOp to server operation "$serverOp"', () async {
        final entry = SyncQueueEntry(
          id: 'entry-$serverOp',
          entityType: SyncEntityType.assessment,
          operation: syncOp,
          payload: {},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        when(() => mockSyncRemote.pushOperations(operations: any(named: 'operations')))
            .thenAnswer((_) async => PushResponseModel(results: [
              OperationResultModel(
                id: 'entry-$serverOp',
                entityType: 'assessment',
                operation: serverOp,
                success: true,
              ),
            ]));

        await handler.syncRegularBatch([entry], DateTime.now());

        final captured = verify(() => mockSyncRemote.pushOperations(
          operations: captureAny(named: 'operations'),
        )).captured;
        final ops = captured.first as List<Map<String, dynamic>>;
        expect(ops.first['operation'], serverOp);
      });
    }
  });
}
