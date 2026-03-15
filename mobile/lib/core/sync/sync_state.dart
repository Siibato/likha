enum SyncPhase { idle, syncing, succeeded, failed }

class SyncState {
  final SyncPhase phase;
  final int pendingCount;
  final int failedCount;
  final String? lastError;
  final DateTime? lastSyncAt;
  final double progress;
  final String? currentStep;
  final bool assessmentsReady;
  final bool assignmentsReady;
  final bool materialsReady;

  const SyncState({
    required this.phase,
    required this.pendingCount,
    required this.failedCount,
    this.lastError,
    this.lastSyncAt,
    this.progress = 0.0,
    this.currentStep,
    this.assessmentsReady = false,
    this.assignmentsReady = false,
    this.materialsReady = false,
  });

  SyncState copyWith({
    SyncPhase? phase,
    int? pendingCount,
    int? failedCount,
    String? lastError,
    DateTime? lastSyncAt,
    double? progress,
    String? currentStep,
    bool? assessmentsReady,
    bool? assignmentsReady,
    bool? materialsReady,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      lastError: lastError ?? this.lastError,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      assessmentsReady: assessmentsReady ?? this.assessmentsReady,
      assignmentsReady: assignmentsReady ?? this.assignmentsReady,
      materialsReady: materialsReady ?? this.materialsReady,
    );
  }
}
