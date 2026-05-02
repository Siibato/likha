import 'dart:async';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/sync/inbound_sync_handler.dart';
import 'package:likha/core/sync/outbound_sync_handler.dart';
import 'package:likha/core/sync/sync_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_state.dart';
import 'package:likha/core/sync/sync_upsert_helpers.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessment_remote_datasource.dart';
import 'package:likha/data/datasources/remote/sync_remote_datasource.dart';
import 'package:likha/services/storage_service.dart';
import 'package:sqflite/sqflite.dart';

export 'package:likha/core/sync/sync_state.dart';

class SyncManager {
  final ServerReachabilityService _serverReachabilityService;
  final SyncQueue _syncQueue;
  final SyncRemoteDataSource _syncRemoteDataSource;
  final LocalDatabase _localDatabase;
  // ignore: unused_field
  final AssessmentRemoteDataSource _assessmentRemoteDataSource;
  // ignore: unused_field
  final AssessmentLocalDataSource _assessmentLocalDataSource;
  final SyncLogger _log;
  final StorageService _storageService;
  final ServerClockService _serverClockService;

  bool _isSyncing = false;
  StreamSubscription<bool>? _reachabilitySubscription;
  void Function(SyncState)? _stateListener;

  SyncState _state = const SyncState(
    phase: SyncPhase.idle,
    pendingCount: 0,
    failedCount: 0,
  );

  // Internal handlers (constructed lazily)
  late final SyncUpsertHelpers _upsertHelpers;
  late final OutboundSyncHandler _outboundHandler;
  late final InboundSyncHandler _inboundHandler;

  SyncState get state => _state;

  SyncManager(
    this._serverReachabilityService,
    this._syncQueue,
    this._syncRemoteDataSource,
    this._localDatabase,
    this._assessmentRemoteDataSource,
    this._assessmentLocalDataSource,
    this._log,
    this._storageService,
    this._serverClockService,
  ) {
    _upsertHelpers = SyncUpsertHelpers(_log);
    _outboundHandler = OutboundSyncHandler(
      _syncQueue,
      _syncRemoteDataSource,
      _localDatabase,
      _log,
      _updateState,
    );
    _inboundHandler = InboundSyncHandler(
      _syncRemoteDataSource,
      _localDatabase,
      _log,
      _upsertHelpers,
      _updateState,
    );
  }

  /// Start sync manager - listen for server reachability changes
  void start() {
    _log.log('start() - START');
    stop(); // cancel any existing subscription to prevent duplicates
    
    _log.log('start() - Setting up reachability listener');
    _reachabilitySubscription =
        _serverReachabilityService.onServerReachabilityChanged.listen((isReachable) {
      _log.log('start() - Reachability changed to: $isReachable, isSyncing: $_isSyncing');
      if (isReachable && !_isSyncing) {
        _log.log('start() - Triggering sync due to reachability change');
        _runSync();
      }
    });

    _log.log('start() - Initial reachability check: ${_serverReachabilityService.isServerReachable}');
    if (_serverReachabilityService.isServerReachable && !_isSyncing) {
      _log.log('start() - Triggering initial sync');
      _runSync();
    } else {
      _log.log('start() - Not triggering sync (reachable: ${_serverReachabilityService.isServerReachable}, syncing: $_isSyncing)');
    }
    
    _log.log('start() - END');
  }

  /// Stop sync manager
  void stop() {
    _reachabilitySubscription?.cancel();
    _reachabilitySubscription = null;
  }

  /// Manually trigger sync
  Future<void> sync() async {
    if (_serverReachabilityService.isServerReachable) {
      await _runSync();
    }
  }

  /// Register listener for sync state changes
  void setStateListener(void Function(SyncState) listener) {
    _stateListener = listener;
  }

  /// Main sync orchestration: outbound then inbound
  Future<void> _runSync() async {
    _log.log('_runSync() - START');
    
    if (!await _storageService.isAuthenticated()) {
      _log.log('_runSync() - Not authenticated, skipping');
      return;
    }
    if (_isSyncing) {
      _log.log('_runSync() - Already syncing, skipping');
      return;
    }
    _isSyncing = true;

    _log.log('_runSync() - Starting sync phase');
    _updateState(phase: SyncPhase.syncing);

    try {
      // STEP 1: Push local mutations to server
      _log.log('_runSync() - Starting outbound sync');
      await _outboundHandler.outboundSync();
      _log.log('_runSync() - Outbound sync completed');

      // STEP 2: Fetch and merge server changes
      _log.log('_runSync() - Starting inbound sync');
      final serverTime = await _inboundHandler.inboundSync();
      _log.log('_runSync() - Inbound sync completed, serverTime: $serverTime');

      // Update server-aligned clock offset for UI time comparisons
      if (serverTime != null) {
        _serverClockService.updateOffset(serverTime);
      }

      // STEP 3: Save last sync time (use server time, not device time)
      final syncTime = serverTime ?? DateTime.now().toIso8601String();
      final db = await _localDatabase.database;
      try {
        await db.update(
          'sync_metadata',
          {'value': syncTime},
          where: 'key = ?',
          whereArgs: ['last_sync_at'],
        );
      } catch (e) {
        // If row doesn't exist, insert it
        await db.insert(
          'sync_metadata',
          {
            'key': 'last_sync_at',
            'value': syncTime,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      _log.log('_runSync() - SUCCESS: Sync completed');
      _updateState(phase: SyncPhase.idle);
    } catch (e) {
      _log.log('_runSync() - ERROR: ${e.toString()}');
      _updateState(phase: SyncPhase.failed, lastError: e.toString());
    } finally {
      _isSyncing = false;
      _log.log('_runSync() - END');
    }
  }

  /// Update sync state and notify listeners
  void _updateState({
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
    _state = _state.copyWith(
      phase: phase,
      pendingCount: pendingCount,
      failedCount: failedCount,
      lastError: lastError,
      lastSyncAt: lastSyncAt,
      progress: progress,
      currentStep: currentStep,
      assessmentsReady: assessmentsReady,
      assignmentsReady: assignmentsReady,
      materialsReady: materialsReady,
    );

    _stateListener?.call(_state);
  }

  /// Resets the in-memory sync state to idle, clearing stale data after logout.
  /// This ensures that the singleton instance doesn't carry over state from previous sessions.
  void reset() {
    stop(); // cancel reachability subscription so no post-logout triggers
    _isSyncing = false;
    _state = const SyncState(
      phase: SyncPhase.idle,
      pendingCount: 0,
      failedCount: 0,
      assessmentsReady: false,
      assignmentsReady: false,
      materialsReady: false,
    );
    _stateListener?.call(_state);
  }
}
