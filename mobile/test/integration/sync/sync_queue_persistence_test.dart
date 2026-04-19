import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_database.dart';

const _uuid = Uuid();

SyncQueueEntry _entry({
  SyncEntityType type = SyncEntityType.assignment,
  SyncOperation operation = SyncOperation.create,
  int maxRetries = 3,
}) {
  return SyncQueueEntry(
    id: _uuid.v4(),
    entityType: type,
    operation: operation,
    payload: {'id': _uuid.v4()},
    status: SyncStatus.pending,
    retryCount: 0,
    maxRetries: maxRetries,
    createdAt: DateTime.now(),
  );
}

void main() {
  late SyncQueueImpl queue;

  setUp(() async {
    await openFreshTestDatabase();
    queue = SyncQueueImpl(LocalDatabase());
  });

  tearDown(() => closeTestDatabase());

  group('SyncQueue persistence', () {
    test('enqueue and getAllRetriable returns pending entry', () async {
      final entry = _entry();
      await queue.enqueue(entry);
      final retriable = await queue.getAllRetriable();
      expect(retriable.any((e) => e.id == entry.id), isTrue);
    });

    test('markSucceeded removes entry from retriable list', () async {
      final entry = _entry();
      await queue.enqueue(entry);
      await queue.markSucceeded(entry.id);
      final retriable = await queue.getAllRetriable();
      expect(retriable.any((e) => e.id == entry.id), isFalse);
    });

    test('markFailed stores error message and removes entry from retriable', () async {
      final entry = _entry(maxRetries: 3);
      await queue.enqueue(entry);
      await queue.markFailed(entry.id, 'Network timeout');

      final retriable = await queue.getAllRetriable();
      expect(retriable.any((e) => e.id == entry.id), isFalse);

      final stored = await queue.getById(entry.id);
      expect(stored, isNotNull);
      expect(stored!.errorMessage, 'Network timeout');
    });

    test('getPendingCount reflects queued entries', () async {
      expect(await queue.getPendingCount(), 0);
      await queue.enqueue(_entry());
      await queue.enqueue(_entry());
      expect(await queue.getPendingCount(), 2);
    });

    test('clear removes all entries', () async {
      await queue.enqueue(_entry());
      await queue.enqueue(_entry());
      await queue.clear();
      expect(await queue.getPendingCount(), 0);
    });
  });
}
