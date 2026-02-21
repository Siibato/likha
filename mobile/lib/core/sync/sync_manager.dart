import 'dart:async';
import 'dart:convert';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/manifest_differ.dart';
import 'package:likha/core/sync/id_reconciler.dart';
import 'package:likha/data/datasources/remote/sync_remote_datasource.dart';
import 'package:likha/data/models/sync/push_response_model.dart';
import 'package:likha/data/models/sync/fetch_response_model.dart';
import 'package:sqflite/sqflite.dart';

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
  final SyncRemoteDataSource _syncRemoteDataSource;
  final LocalDatabase _localDatabase;

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
    this._syncRemoteDataSource,
    this._localDatabase,
  );

  /// Start sync manager - listen for connectivity changes
  void start() {
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline && !_isSyncing) {
        _runSync();
      }
    });
  }

  /// Stop sync manager
  void stop() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Manually trigger sync
  Future<void> sync() async {
    if (_connectivityService.isOnline) {
      await _runSync();
    }
  }

  /// Register listener for sync state changes
  void setStateListener(void Function(SyncState) listener) {
    _stateListener = listener;
  }

  /// Main sync orchestration: outbound then inbound
  Future<void> _runSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    _updateState(phase: SyncPhase.syncing);

    try {
      // STEP 1: Push local mutations to server
      await _outboundSync();

      // STEP 2: Fetch and merge server changes
      final serverTime = await _inboundSync();

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

      _updateState(phase: SyncPhase.succeeded, lastSyncAt: DateTime.now());
    } catch (e) {
      _updateState(
        phase: SyncPhase.failed,
        lastError: e.toString(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// OUTBOUND SYNC: Push queued mutations to server
  Future<void> _outboundSync() async {
    // Get all pending operations from queue
    final pending = await _syncQueue.getAllRetriable();
    if (pending.isEmpty) return;

    _updateState(pendingCount: pending.length);

    // Format operations for server
    final operations = pending.map((entry) {
      return {
        'id': entry.id,
        'entity_type': entry.entityType.toString().split('.').last,
        'operation': entry.operation.toString().split('.').last,
        'payload': entry.payload,
      };
    }).toList();

    // Send to server
    final response = await _syncRemoteDataSource.pushOperations(
      operations: operations,
    );

    // Process results
    await _processPushResults(response);
  }

  /// Process push results and update local state
  Future<void> _processPushResults(PushResponseModel response) async {
    final db = await _localDatabase.database;
    final idMappings = <({String entityType, String localId, String serverId})>[];

    for (final result in response.results) {
      final opId = result.id;
      final success = result.success;
      final serverId = result.serverId;
      final entityType = result.entityType;
      final operation = result.operation;

      // Fetch entry BEFORE marking succeeded (entry is hard-deleted on succeed)
      final entry = await _syncQueue.getById(opId);

      if (success) {
        // Mark as succeeded and remove from queue
        await _syncQueue.markSucceeded(opId);

        // If this was a create operation, map local ID to server ID
        if (serverId != null && operation == 'create' && entry != null) {
          final localId = entry.payload['local_id'] as String?;
          if (localId != null) {
            idMappings.add(
              (entityType: entityType, localId: localId, serverId: serverId),
            );
          }
        }
      } else {
        // Mark as failed
        final error = result.error ?? 'Unknown error';
        await _syncQueue.markFailed(opId, error);
      }
    }

    // Apply ID reconciliations using IdReconciler
    if (idMappings.isNotEmpty) {
      await IdReconciler.applyToDatabase(db, idMappings);
    }
  }

  /// INBOUND SYNC: Fetch server changes
  /// Returns server time to use for last_sync_at
  Future<String?> _inboundSync() async {
    // Step 1: Get manifest from server
    final manifest = await _syncRemoteDataSource.getManifest();

    // Step 2: Get local snapshots for comparison
    final db = await _localDatabase.database;
    final localSnapshots = await _getLocalSnapshots(db);

    // Step 3: Find stale records and tombstones
    final toFetch = ManifestDiffer.findStaleRecords(
      serverManifest: manifest,
      localManifest: localSnapshots,
    );
    final tombstones = ManifestDiffer.findTombstones(manifest);

    // Step 4: Apply tombstones (soft delete marked records)
    for (final entry in tombstones) {
      final entityType = entry['entity_type'] as String;
      final entityId = entry['id'] as String;

      await db.update(
        _entityTypeToTableName(entityType),
        {'deleted_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [entityId],
      );
    }

    // Step 5: Fetch records by entity type with pagination
    for (final entityType in toFetch.keys) {
      final ids = toFetch[entityType] ?? [];
      if (ids.isEmpty) continue;

      await _fetchAndMergeRecords(entityType, ids);
    }

    // Return server time for last_sync_at
    return manifest.serverTime;
  }

  /// Fetch records for entity type and merge into local DB
  Future<void> _fetchAndMergeRecords(
    String entityType,
    List<String> ids,
  ) async {
    String? cursor;
    bool hasMore = true;

    while (hasMore) {
      final response = await _syncRemoteDataSource.fetchRecords(
        entities: {entityType: ids},
        cursor: cursor,
      );

      final records = response.entities[entityType] ?? [];
      if (records.isEmpty) break;

      // Merge records into local DB
      final db = await _localDatabase.database;
      final tableName = _entityTypeToTableName(entityType);

      for (final record in records) {
        await db.insert(
          tableName,
          {
            ...record as Map<String, dynamic>,
            'sync_status': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      cursor = response.cursor;
      hasMore = response.hasMore;
    }
  }

  /// Get local snapshots for manifest comparison
  Future<Map<String, Map<String, LocalManifestEntry>>> _getLocalSnapshots(
    Database db,
  ) async {
    final snapshots = <String, Map<String, LocalManifestEntry>>{};

    final entityTables = {
      'classes': 'classes',
      'assessments': 'assessments',
      'assignments': 'assignments',
      'learning_materials': 'learning_materials',
      'assessment_submissions': 'assessment_submissions',
      'assignment_submissions': 'assignment_submissions',
      'assessment_questions': 'questions',
      'class_enrollments': 'class_enrollments',
    };

    for (final entry in entityTables.entries) {
      final entityType = entry.key;
      final tableName = entry.value;

      try {
        final rows = await db.query(
          tableName,
          columns: ['id', 'updated_at', 'deleted_at'],
        );

        final manifestEntries = <String, LocalManifestEntry>{};
        for (final row in rows) {
          final id = row['id'] as String;
          manifestEntries[id] = LocalManifestEntry(
            id: id,
            updatedAt: row['updated_at'] as String? ?? DateTime.now().toIso8601String(),
            deleted: row['deleted_at'] != null,
          );
        }
        snapshots[entityType] = manifestEntries;
      } catch (e) {
        // Table might not exist or be empty
        snapshots[entityType] = {};
      }
    }

    return snapshots;
  }

  /// Map entity type to database table name
  String _entityTypeToTableName(String entityType) {
    switch (entityType) {
      case 'classes':
        return 'classes';
      case 'assessments':
        return 'assessments';
      case 'assignments':
        return 'assignments';
      case 'learning_materials':
        return 'learning_materials';
      case 'assessment_submissions':
        return 'assessment_submissions';
      case 'assignment_submissions':
        return 'assignment_submissions';
      case 'questions':
        return 'questions';
      case 'class_enrollments':
        return 'class_enrollments';
      default:
        return entityType;
    }
  }

  /// Update sync state and notify listeners
  void _updateState({
    SyncPhase? phase,
    int? pendingCount,
    int? failedCount,
    String? lastError,
    DateTime? lastSyncAt,
  }) {
    _state = _state.copyWith(
      phase: phase,
      pendingCount: pendingCount,
      failedCount: failedCount,
      lastError: lastError,
      lastSyncAt: lastSyncAt,
    );

    _stateListener?.call(_state);
  }
}
