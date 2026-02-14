import 'dart:async';

import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

enum SyncPhase { idle, syncing, succeeded, failed }

class SyncState {
  final SyncPhase phase;
  final int pendingCount;
  final int failedCount;
  final String? lastError;
  final DateTime? lastSyncAt;

  const SyncState({
    required this.phase,
    required this.pendingCount,
    required this.failedCount,
    this.lastError,
    this.lastSyncAt,
  });

  SyncState copyWith({
    SyncPhase? phase,
    int? pendingCount,
    int? failedCount,
    String? lastError,
    DateTime? lastSyncAt,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      lastError: lastError ?? this.lastError,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

class SyncManager {
  final ConnectivityService _connectivityService;
  final SyncQueue _syncQueue;
  final AuthRepository _authRepository;
  final ClassRepository _classRepository;
  final AssessmentRepository _assessmentRepository;
  final AssignmentRepository _assignmentRepository;
  final LearningMaterialRepository _learningMaterialRepository;

  bool _isSyncing = false;
  StreamSubscription<bool>? _connectivitySubscription;
  void Function(SyncState)? _stateListener;

  SyncState _state = const SyncState(
    phase: SyncPhase.idle,
    pendingCount: 0,
    failedCount: 0,
  );

  SyncState get state => _state;

  SyncManager(
    this._connectivityService,
    this._syncQueue,
    this._authRepository,
    this._classRepository,
    this._assessmentRepository,
    this._assignmentRepository,
    this._learningMaterialRepository,
  );

  void setStateListener(void Function(SyncState) listener) {
    _stateListener = listener;
  }

  void start() {
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline && !_isSyncing) {
        _runSync();
      }
    });

    // Initial count
    _updateCounts();
  }

  Future<void> _runSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _emitState(_state.copyWith(phase: SyncPhase.syncing));

    try {
      // Get all retryable entries
      final entries = await _syncQueue.getAllRetriable();

      if (entries.isEmpty) {
        // Refresh cache if online
        await _refreshCache();
        _emitState(_state.copyWith(
          phase: SyncPhase.succeeded,
          lastSyncAt: DateTime.now(),
        ));
        _isSyncing = false;
        return;
      }

      // Flush pending syncs
      int failedCount = 0;
      for (final entry in entries) {
        try {
          await _syncQueue.incrementRetry(entry.id);
          await _dispatchSyncOperation(entry);
          await _syncQueue.markSucceeded(entry.id);
        } catch (e) {
          await _syncQueue.markFailed(entry.id, e.toString());
          failedCount++;
        }
      }

      // Refresh cache
      await _refreshCache();

      // Update state
      await _updateCounts();
      final finalFailedCount = (await _syncQueue.getAllRetriable())
          .where((e) => e.status == SyncStatus.failed)
          .length;

      if (finalFailedCount > 0) {
        _emitState(_state.copyWith(
          phase: SyncPhase.failed,
          failedCount: finalFailedCount,
          lastError: 'Some syncs failed',
          lastSyncAt: DateTime.now(),
        ));
      } else {
        _emitState(_state.copyWith(
          phase: SyncPhase.succeeded,
          pendingCount: 0,
          failedCount: 0,
          lastSyncAt: DateTime.now(),
        ));
      }
    } catch (e) {
      _emitState(_state.copyWith(
        phase: SyncPhase.failed,
        lastError: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _dispatchSyncOperation(SyncQueueEntry entry) async {
    switch (entry.entityType) {
      case SyncEntityType.classEntity:
        await _syncClassOperation(entry);
        break;
      case SyncEntityType.assessment:
        await _syncAssessmentOperation(entry);
        break;
      case SyncEntityType.assignmentSubmission:
        await _syncAssignmentSubmissionOperation(entry);
        break;
      case SyncEntityType.learningMaterial:
        await _syncLearningMaterialOperation(entry);
        break;
      default:
        // Other entity types would be handled similarly
        break;
    }
  }

  Future<void> _syncClassOperation(SyncQueueEntry entry) async {
    // Dispatch to appropriate class repository method
    // This is a simplified version - in production, would handle all operations
    final classId = entry.payload['id'] as String?;
    if (classId == null) throw Exception('Missing classId in payload');

    // The repository would handle the actual sync
    // For now, this is a placeholder that would be filled in during Phase 3
  }

  Future<void> _syncAssessmentOperation(SyncQueueEntry entry) async {
    // Similar pattern for assessments
  }

  Future<void> _syncAssignmentSubmissionOperation(SyncQueueEntry entry) async {
    // Similar pattern for assignments
  }

  Future<void> _syncLearningMaterialOperation(SyncQueueEntry entry) async {
    // Similar pattern for learning materials
  }

  Future<void> _refreshCache() async {
    try {
      // Get current user
      final userResult = await _authRepository.getCurrentUser();
      userResult.fold(
        (failure) {}, // Ignore failures during refresh
        (user) {}, // User cached by repository
      );

      // In a full implementation, would refresh all cached data
      // This is a simplified version
    } catch (_) {
      // Best-effort refresh - errors don't fail the sync
    }
  }

  Future<void> _updateCounts() async {
    final entries = await _syncQueue.getAllRetriable();
    final pendingCount = entries.where((e) => e.status == SyncStatus.pending).length;
    final failedCount = entries.where((e) => e.status == SyncStatus.failed).length;

    _emitState(_state.copyWith(
      pendingCount: pendingCount,
      failedCount: failedCount,
    ));
  }

  void _emitState(SyncState newState) {
    _state = newState;
    _stateListener?.call(newState);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
