import 'dart:async';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/sync/handlers/assessment_sync_handler.dart';
import 'package:likha/core/sync/handlers/assignment_sync_handler.dart';
import 'package:likha/core/sync/handlers/auth_sync_handler.dart';
import 'package:likha/core/sync/handlers/class_sync_handler.dart';
import 'package:likha/core/sync/handlers/grading_sync_handler.dart';
import 'package:likha/core/sync/handlers/learning_material_sync_handler.dart';
import 'package:likha/core/sync/handlers/setup_sync_handler.dart';
import 'package:likha/core/sync/handlers/student_records_sync_handler.dart';
import 'package:likha/core/sync/handlers/tos_sync_handler.dart';
import 'package:likha/core/sync/inbound_sync_handler.dart';
import 'package:likha/core/sync/outbound_sync_handler.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_state.dart';
import 'package:likha/core/sync/sync_upsert_helpers.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/data/datasources/remote/setup/setup_remote_datasource.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';
import 'package:likha/data/datasources/remote/sync/sync_remote_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/services/storage_service.dart';

export 'package:likha/core/sync/sync_state.dart';

class SyncManager {
  final ServerReachabilityService _serverReachabilityService;
  final SyncQueue _syncQueue;
  final SyncRemoteDataSource _syncRemoteDataSource;
  final LocalDatabase _localDatabase;
  final AssessmentRemoteDataSource _assessmentRemoteDataSource;
  final AssessmentLocalDataSource _assessmentLocalDataSource;
  final AssignmentRemoteDataSource _assignmentRemoteDataSource;
  final AssignmentLocalDataSource _assignmentLocalDataSource;
  final AuthRemoteDataSource _authRemoteDataSource;
  final AuthLocalDataSource _authLocalDataSource;
  final ClassRemoteDataSource _classRemoteDataSource;
  final ClassLocalDataSource _classLocalDataSource;
  final GradingRemoteDataSource _gradingRemoteDataSource;
  final GradingLocalDataSource _gradingLocalDataSource;
  final LearningMaterialRemoteDataSource _learningMaterialRemoteDataSource;
  final LearningMaterialLocalDataSource _learningMaterialLocalDataSource;
  final SetupRemoteDataSource _setupRemoteDataSource;
  final StudentRecordsRemoteDataSource _studentRecordsRemoteDataSource;
  final TosRemoteDataSource _tosRemoteDataSource;
  final TosLocalDataSource _tosLocalDataSource;
  final SyncLogger _log;
  final StorageService _storageService;
  final ServerClockService _serverClockService;
  final DataEventBus _dataEventBus;

  bool _isSyncing = false;
  StreamSubscription<bool>? _reachabilitySubscription;
  StreamSubscription<SyncQueueEntry>? _queueSubscription;
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
    this._assignmentRemoteDataSource,
    this._assignmentLocalDataSource,
    this._authRemoteDataSource,
    this._authLocalDataSource,
    this._classRemoteDataSource,
    this._classLocalDataSource,
    this._gradingRemoteDataSource,
    this._gradingLocalDataSource,
    this._learningMaterialRemoteDataSource,
    this._learningMaterialLocalDataSource,
    this._setupRemoteDataSource,
    this._studentRecordsRemoteDataSource,
    this._tosRemoteDataSource,
    this._tosLocalDataSource,
    this._log,
    this._storageService,
    this._serverClockService,
    this._dataEventBus,
  ) {
    _upsertHelpers = SyncUpsertHelpers(_log);
    _outboundHandler = OutboundSyncHandler(
      _syncQueue,
      _syncRemoteDataSource,
      _localDatabase,
      _log,
      _updateState,
      assessmentHandler: AssessmentSyncHandler(
        _assessmentRemoteDataSource,
        _assessmentLocalDataSource,
        _localDatabase,
        _log,
      ),
      assignmentHandler: AssignmentSyncHandler(
        _assignmentRemoteDataSource,
        _assignmentLocalDataSource,
        _localDatabase,
        _log,
        _dataEventBus,
      ),
      authHandler: AuthSyncHandler(
        _authRemoteDataSource,
        _authLocalDataSource,
        _localDatabase,
        _log,
      ),
      classHandler: ClassSyncHandler(
        _classRemoteDataSource,
        _classLocalDataSource,
        _localDatabase,
        _log,
      ),
      gradingHandler: GradingSyncHandler(
        _gradingRemoteDataSource,
        _gradingLocalDataSource,
        _localDatabase,
        _log,
        _dataEventBus,
      ),
      learningMaterialHandler: LearningMaterialSyncHandler(
        _learningMaterialRemoteDataSource,
        _learningMaterialLocalDataSource,
        _localDatabase,
        _log,
      ),
      tosHandler: TosSyncHandler(
        _tosRemoteDataSource,
        _tosLocalDataSource,
        _localDatabase,
        _log,
      ),
      setupHandler: SetupSyncHandler(
        _setupRemoteDataSource,
        _localDatabase,
        _dataEventBus,
      ),
      studentRecordsHandler: StudentRecordsSyncHandler(
        _studentRecordsRemoteDataSource,
        _localDatabase,
        _log,
      ),
    );
    _inboundHandler = InboundSyncHandler(
      _syncRemoteDataSource,
      _localDatabase,
      _log,
      _upsertHelpers,
      _updateState,
      _dataEventBus,
    );
  }

  /// Start sync manager - listen for server reachability changes
  Future<void> start() async {
    _log.log('start() - START');
    stop(); // cancel any existing subscription to prevent duplicates

    // Seed lastSyncAt from persisted metadata BEFORE triggering any sync so
    // returning users don't briefly see the first-sync loading screen.
    await _loadLastSyncTime();

    _log.log('start() - Setting up reachability listener');
    _reachabilitySubscription =
        _serverReachabilityService.onServerReachabilityChanged.listen((isReachable) {
      _log.log('start() - Reachability changed to: $isReachable, isSyncing: $_isSyncing');
      if (isReachable && !_isSyncing) {
        _log.log('start() - Triggering sync due to reachability change');
        _runSync();
      }
    });

    _log.log('start() - Setting up queue entry listener');
    _queueSubscription = _syncQueue.onEntryAdded.listen((entry) async {
      _log.log('start() - Queue entry added: ${entry.entityType.dbValue}.${entry.operation.dbValue}');

      if (_isSyncing) {
        _log.log('start() - Already syncing, skipping immediate flush');
        return;
      }

      if (!_serverReachabilityService.isServerReachable) {
        _log.log('start() - Cached reachability false, performing live check');
        final now = await _serverReachabilityService.checkNow();
        if (!now) {
          _log.log('start() - Live check confirms offline, deferring');
          return;
        }
        _log.log('start() - Live check confirms online');
      }

      _log.log('start() - Triggering sync for new entry');
      _runSync();
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
    _queueSubscription?.cancel();
    _queueSubscription = null;
  }

  /// Manually trigger sync
  Future<void> sync() async {
    if (_isSyncing) return;

    if (!_serverReachabilityService.isServerReachable) {
      final now = await _serverReachabilityService.checkNow();
      if (!now) return;
    }

    await _runSync();
  }

  /// Register listener for sync state changes
  void setStateListener(void Function(SyncState)? listener) {
    _stateListener = listener;
  }

  /// Load the persisted last sync time from sync_metadata and seed the
  /// in-memory state. This prevents the first-sync loading screen from showing
  /// for returning users whose data was already synced in a prior session.
  Future<void> _loadLastSyncTime() async {
    if (_state.lastSyncAt != null) return;
    try {
      final value = await _localDatabase.getLastSyncAt();
      final parsed = value == null ? null : DateTime.tryParse(value);
      if (parsed != null) {
        _updateState(lastSyncAt: parsed);
      }
    } catch (e) {
      _log.log('_loadLastSyncTime() - ERROR: ${e.toString()}');
    }
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
      await _localDatabase.setLastSyncAt(syncTime);

      _log.log('_runSync() - SUCCESS: Sync completed');
      final parsedSyncTime = DateTime.tryParse(syncTime);
      _updateState(phase: SyncPhase.idle, lastSyncAt: parsedSyncTime);
    } catch (e) {
      _log.log('_runSync() - ERROR: ${e.toString()}');
      _updateState(phase: SyncPhase.failed, lastError: e.toString());
    } finally {
      _isSyncing = false;
      _log.log('_runSync() - END');

      // Re-flush any entries that arrived while we were busy syncing
      final pendingCount = await _syncQueue.getPendingCount();
      if (pendingCount > 0) {
        _log.log('_runSync() - $pendingCount new queue entries arrived during sync, re-flushing');
        _runSync();
      }
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
