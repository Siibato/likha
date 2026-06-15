/// Result of a sync handler processing a single [SyncQueueEntry].
///
/// - [SyncResult.success] — remote call succeeded; local state should be reconciled.
/// - [SyncResult.retry] — transient failure (e.g. [NetworkException]); the Sync
///   Engine will schedule a backoff retry.
/// - [SyncResult.permanentFailure] — non-retryable error (e.g. 4xx/5xx); marks
///   the entry as failed and surfaces an error indicator in the UI.
class SyncResult {
  final bool success;
  final bool shouldRetry;
  final String? error;

  /// Server-assigned ID for create operations; used to reconcile local UUIDs.
  final String? serverId;

  const SyncResult.success({this.serverId})
      : success = true,
        shouldRetry = false,
        error = null;

  const SyncResult.retry(this.error)
      : success = false,
        shouldRetry = true,
        serverId = null;

  const SyncResult.permanentFailure(this.error)
      : success = false,
        shouldRetry = false,
        serverId = null;
}
