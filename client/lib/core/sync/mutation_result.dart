import 'package:likha/core/sync/sync_queue.dart';

/// Result returned by write repository operations.
///
/// The entity is always the optimistic/local version that was written to SQLite.
/// The [status] indicates where the entity is in the sync lifecycle:
/// - [SyncStatus.pending]: queued for sync, not yet sent
/// - [SyncStatus.syncing]: currently being sent to the server
/// - [SyncStatus.synced]: successfully acknowledged by the server
/// - [SyncStatus.failed]: server rejected (4xx/5xx), needs user attention
class MutationResult<T> {
  final T entity;
  final SyncStatus status;

  const MutationResult({
    required this.entity,
    required this.status,
  });
}
