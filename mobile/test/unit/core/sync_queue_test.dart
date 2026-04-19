import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:likha/core/sync/sync_queue.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'SYNC_LOGGING_ENABLED=false');
  });

  group('SyncEntityType', () {
    test('dbValue matches Dart enum name', () {
      expect(SyncEntityType.user.dbValue, 'user');
      expect(SyncEntityType.classEntity.dbValue, 'classEntity');
      expect(SyncEntityType.assessment.dbValue, 'assessment');
      expect(SyncEntityType.gradeItem.dbValue, 'gradeItem');
    });

    test('serverValue is correct snake_case', () {
      expect(SyncEntityType.user.serverValue, 'user');
      expect(SyncEntityType.classEntity.serverValue, 'class');
      expect(SyncEntityType.gradeItem.serverValue, 'grade_item');
      expect(SyncEntityType.tosCompetency.serverValue, 'tos_competency');
    });

    test('all enum values have serverValue defined', () {
      for (final type in SyncEntityType.values) {
        expect(type.serverValue, isNotEmpty);
      }
    });
  });

  group('SyncOperation', () {
    test('dbValue matches Dart enum name', () {
      expect(SyncOperation.create.dbValue, 'create');
      expect(SyncOperation.update.dbValue, 'update');
      expect(SyncOperation.delete.dbValue, 'delete');
      expect(SyncOperation.saveScores.dbValue, 'saveScores');
    });

    test('serverValue is correct format', () {
      expect(SyncOperation.create.serverValue, 'create');
      expect(SyncOperation.saveAnswers.serverValue, 'save_answers');
      expect(SyncOperation.releaseResults.serverValue, 'release_results');
      expect(SyncOperation.overrideAnswer.serverValue, 'override_answer');
    });

    test('all enum values have serverValue defined', () {
      for (final op in SyncOperation.values) {
        expect(op.serverValue, isNotEmpty);
      }
    });
  });

  group('SyncStatus', () {
    test('dbValue matches Dart enum name', () {
      expect(SyncStatus.pending.dbValue, 'pending');
      expect(SyncStatus.failed.dbValue, 'failed');
      expect(SyncStatus.succeeded.dbValue, 'succeeded');
    });
  });

  group('SyncQueueEntry', () {
    test('toMap serializes all fields', () {
      final entry = SyncQueueEntry(
        id: 'entry-1',
        entityType: SyncEntityType.assignment,
        operation: SyncOperation.create,
        payload: {'title': 'Test Assignment'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime(2024, 1, 1),
      );

      final map = entry.toMap();

      expect(map['id'], 'entry-1');
      expect(map['entity_type'], 'assignment'); // SyncEntityType.assignment.dbValue == 'assignment'
      expect(map['operation'], 'create');
      expect(map['status'], 'pending');
      expect(map['retry_count'], 0);
      expect(map['max_retries'], 3);
      expect(map['error_message'], isNull);
    });

    test('toMap serializes payload as JSON string', () {
      final entry = SyncQueueEntry(
        id: 'entry-1',
        entityType: SyncEntityType.gradeScore,
        operation: SyncOperation.saveScores,
        payload: {'score': 95.0, 'studentId': 'student-1'},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime(2024, 1, 1),
      );

      final map = entry.toMap();
      expect(map['payload'], isA<String>());
      expect(map['payload'], contains('score'));
    });

    test('fromMap round-trips with toMap', () {
      final original = SyncQueueEntry(
        id: 'entry-round-trip',
        entityType: SyncEntityType.assessment,
        operation: SyncOperation.publish,
        payload: {'assessmentId': 'assess-1'},
        status: SyncStatus.failed,
        retryCount: 2,
        maxRetries: 3,
        createdAt: DateTime(2024, 6, 15),
        errorMessage: 'Network timeout',
      );

      final map = original.toMap();
      final restored = SyncQueueEntry.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.entityType, original.entityType);
      expect(restored.operation, original.operation);
      expect(restored.status, original.status);
      expect(restored.retryCount, original.retryCount);
      expect(restored.maxRetries, original.maxRetries);
      expect(restored.errorMessage, original.errorMessage);
      expect(restored.payload['assessmentId'], 'assess-1');
    });

    test('fromMap handles unknown entityType gracefully', () {
      final map = {
        'id': 'entry-1',
        'entity_type': 'unknown_entity',
        'operation': 'create',
        'payload': '{}',
        'status': 'pending',
        'retry_count': 0,
        'max_retries': 3,
        'created_at': '2024-01-01T00:00:00.000',
        'last_attempted_at': null,
        'error_message': null,
      };

      final entry = SyncQueueEntry.fromMap(map);
      // Falls back to SyncEntityType.user on unknown value
      expect(entry.entityType, SyncEntityType.user);
    });

    test('fromMap handles unknown operation gracefully', () {
      final map = {
        'id': 'entry-1',
        'entity_type': 'user',
        'operation': 'unknown_op',
        'payload': '{}',
        'status': 'pending',
        'retry_count': 0,
        'max_retries': 3,
        'created_at': '2024-01-01T00:00:00.000',
        'last_attempted_at': null,
        'error_message': null,
      };

      final entry = SyncQueueEntry.fromMap(map);
      // Falls back to SyncOperation.create on unknown value
      expect(entry.operation, SyncOperation.create);
    });

    test('fromMap handles invalid payload JSON gracefully', () {
      final map = {
        'id': 'entry-1',
        'entity_type': 'user',
        'operation': 'create',
        'payload': 'not valid json {{{',
        'status': 'pending',
        'retry_count': 0,
        'max_retries': 3,
        'created_at': '2024-01-01T00:00:00.000',
        'last_attempted_at': null,
        'error_message': null,
      };

      final entry = SyncQueueEntry.fromMap(map);
      expect(entry.payload, isEmpty);
    });

    test('toMap includes lastAttemptedAt when set', () {
      final entry = SyncQueueEntry(
        id: 'entry-1',
        entityType: SyncEntityType.user,
        operation: SyncOperation.update,
        payload: {},
        status: SyncStatus.failed,
        retryCount: 1,
        maxRetries: 3,
        createdAt: DateTime(2024, 1, 1),
        lastAttemptedAt: DateTime(2024, 1, 2),
        errorMessage: 'Timeout',
      );

      final map = entry.toMap();
      expect(map['last_attempted_at'], isNotNull);
      expect(map['error_message'], 'Timeout');
    });
  });
}
