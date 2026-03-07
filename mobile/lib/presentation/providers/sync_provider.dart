import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/injection_container.dart';

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncManager _syncManager;
  final SyncQueue _syncQueue;

  SyncNotifier(this._syncManager, this._syncQueue)
      : super(_syncManager.state) {
    _init();
  }

  Future<void> _init() async {
    // Register listener for sync state changes
    _syncManager.setStateListener((newState) {
      state = newState;
    });

    // Initial counts
    await _updateCounts();
  }

  Future<void> _updateCounts() async {
    final entries = await _syncQueue.getAllRetriable();
    final pendingCount = entries.where((e) => e.status == SyncStatus.pending).length;
    final failedCount = entries.where((e) => e.status == SyncStatus.failed).length;

    state = state.copyWith(
      pendingCount: pendingCount,
      failedCount: failedCount,
    );
  }

  Future<void> refreshCounts() => _updateCounts();
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(sl<SyncManager>(), sl<SyncQueue>());
});

final syncPhaseProvider = Provider<SyncPhase>((ref) {
  return ref.watch(syncProvider).phase;
});

final syncPendingCountProvider = Provider<int>((ref) {
  return ref.watch(syncProvider).pendingCount;
});

final syncFailedCountProvider = Provider<int>((ref) {
  return ref.watch(syncProvider).failedCount;
});

final syncLastErrorProvider = Provider<String?>((ref) {
  return ref.watch(syncProvider).lastError;
});

final syncLastSyncAtProvider = Provider<DateTime?>((ref) {
  return ref.watch(syncProvider).lastSyncAt;
});

final syncAssessmentsReadyProvider = Provider<bool>((ref) {
  return ref.watch(syncProvider).assessmentsReady;
});

final syncAssignmentsReadyProvider = Provider<bool>((ref) {
  return ref.watch(syncProvider).assignmentsReady;
});

final syncMaterialsReadyProvider = Provider<bool>((ref) {
  return ref.watch(syncProvider).materialsReady;
});
