import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/id_reconciler.dart';
import 'package:likha/data/datasources/remote/sync_remote_datasource.dart';
import 'package:likha/data/models/sync/push_response_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

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
  final ServerReachabilityService _serverReachabilityService;
  final SyncQueue _syncQueue;
  final SyncRemoteDataSource _syncRemoteDataSource;
  final LocalDatabase _localDatabase;

  bool _isSyncing = false;
  StreamSubscription<bool>? _reachabilitySubscription;
  void Function(SyncState)? _stateListener;

  SyncState _state = const SyncState(
    phase: SyncPhase.idle,
    pendingCount: 0,
    failedCount: 0,
  );

  SyncState get state => _state;

  SyncManager(
    this._serverReachabilityService,
    this._syncQueue,
    this._syncRemoteDataSource,
    this._localDatabase,
  );

  /// Start sync manager - listen for server reachability changes
  void start() {
    _reachabilitySubscription =
        _serverReachabilityService.onServerReachabilityChanged.listen((isReachable) {
      if (isReachable && !_isSyncing) {
        _runSync();
      }
    });
    
    if (_serverReachabilityService.isServerReachable && !_isSyncing) {
      _runSync();
    }
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

    // Split: upload ops need direct multipart POST, not JSON batch
    final uploadOps   = pending.where((e) => e.operation == SyncOperation.upload).toList();
    final regularOps  = pending.where((e) => e.operation != SyncOperation.upload).toList();

    // Handle file uploads directly via multipart endpoint
    for (final op in uploadOps) {
      await _handleFileUpload(op);
    }

    // Handle all other operations via the batch push endpoint
    if (regularOps.isNotEmpty) {
      _updateState(pendingCount: regularOps.length);

      final operations = regularOps.map((entry) {
        return {
          'id':          entry.id,
          'entity_type': _entityTypeToServer(entry.entityType),
          'operation':   _operationToServer(entry.operation),
          'payload':     entry.payload,
        };
      }).toList();

      final response = await _syncRemoteDataSource.pushOperations(
        operations: operations,
      );

      await _processPushResults(response);
    }
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

            // Special handling for classes: update main ID from local UUID to server UUID
            if (entityType == 'classEntity') {
              await db.update(
                'classes',
                {'id': serverId},
                where: 'id = ?',
                whereArgs: [localId],
              );
            }

            // Special handling for questions: update main ID and reconcile nested IDs
            if (entityType == 'question') {
              // Update the question's main ID from local UUID to server UUID
              await db.update(
                'questions',
                {'id': serverId},
                where: 'id = ?',
                whereArgs: [localId],
              );
              // Then reconcile nested choice and answer IDs
              await _reconcileQuestionNestedIds(db, serverId, result);
            }
          }
        }

        // Handle enrollment ID reconciliation for add_enrollment operations
        if (serverId != null && operation == 'add_enrollment' && entry != null) {
          final localEnrollmentId = entry.payload['local_enrollment_id'] as String?;
          if (localEnrollmentId != null) {
            // Update the enrollment record from local UUID to server UUID
            await db.update(
              'class_enrollments',
              {'id': serverId, 'sync_status': 'synced'},
              where: 'id = ?',
              whereArgs: [localEnrollmentId],
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

  /// Reconcile nested IDs for questions (choices, correct_answers)
  Future<void> _reconcileQuestionNestedIds(
    Database db,
    String serverQuestionId,
    OperationResultModel result,
  ) async {
    // Extract metadata containing ID mappings from server response
    final metadata = result.metadata;
    if (metadata == null) return;

    // Update choice IDs in the questions table
    final choiceMapping = metadata['choice_id_mapping'] as List<dynamic>?;
    if (choiceMapping != null && choiceMapping.isNotEmpty) {
      await _updateNestedIdsInJson(
        db,
        'questions',
        serverQuestionId,
        'choices_json',
        choiceMapping,
      );
    }

    // Update correct answer IDs in the questions table
    final answerMapping = metadata['answer_id_mapping'] as List<dynamic>?;
    if (answerMapping != null && answerMapping.isNotEmpty) {
      await _updateNestedIdsInJson(
        db,
        'questions',
        serverQuestionId,
        'correct_answers_json',
        answerMapping,
      );
    }
  }

  /// Update nested IDs within a JSON field (for choices or correct answers)
  Future<void> _updateNestedIdsInJson(
    Database db,
    String tableName,
    String questionId,
    String jsonField,
    List<dynamic> idMappings,
  ) async {
    try {
      // Query the current JSON data
      final results = await db.query(
        tableName,
        columns: [jsonField],
        where: 'id = ?',
        whereArgs: [questionId],
      );

      if (results.isEmpty) return;

      final jsonStr = results.first[jsonField] as String?;
      if (jsonStr == null || jsonStr.isEmpty) return;

      // Parse JSON
      final List<dynamic> items = jsonDecode(jsonStr) as List<dynamic>;

      // Build ID mapping from list of [local_id, server_id] pairs
      final Map<String, String> mapping = {};
      for (final pair in idMappings) {
        if (pair is List && pair.length == 2) {
          mapping[pair[0] as String] = pair[1] as String;
        }
      }

      // Update IDs in items
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final oldId = item['id'] as String?;
          if (oldId != null && mapping.containsKey(oldId)) {
            item['id'] = mapping[oldId];
          }
        }
      }

      // Write back to database
      await db.update(
        tableName,
        {jsonField: jsonEncode(items)},
        where: 'id = ?',
        whereArgs: [questionId],
      );
    } catch (e) {
      // Log but don't throw - ID reconciliation failure shouldn't block sync
      // In production, this would go to a logger
    }
  }

  /// INBOUND SYNC: Fetch server changes (full or delta)
  /// Returns server time to use for last_sync_at
  Future<String?> _inboundSync() async {
    final db = await _localDatabase.database;

    // Check for last_sync_at
    final rows = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['last_sync_at'],
    );
    final lastSyncAt = rows.isNotEmpty ? rows.first['value'] as String? : null;

    final expiryRows = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['data_expiry_at'],
    );
    final dataExpiryAt = expiryRows.isNotEmpty ? expiryRows.first['value'] as String? : null;

    if (lastSyncAt == null) {
      // FIRST LOGIN: full sync
      return await _runFullSync();
    } else {
      // APP RESTART: delta sync
      final deltaResult = await _runDeltaSync(lastSyncAt, dataExpiryAt);
      if (deltaResult == null) {
        // data_expired → fall back to full sync
        return await _runFullSync();
      }
      return deltaResult;
    }
  }

  /// Run full sync on first login
  Future<String?> _runFullSync() async {
    // Get device ID (or generate and store)
    final db = await _localDatabase.database;
    final deviceIdRows = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['device_id'],
    );
    final deviceId = deviceIdRows.isNotEmpty
        ? deviceIdRows.first['value'] as String
        : _generateAndStoreDeviceId(db);

    // Fetch full sync data
    final response = await _syncRemoteDataSource.fullSync(deviceId: deviceId);
    final syncToken = response['sync_token'] as String?;
    final serverTime = response['server_time'] as String?;

    if (syncToken == null) {
      throw Exception('No sync_token in full sync response');
    }

    // Upsert all entity data
    await _upsertEntity(db, 'classes', response['classes'] ?? []);
    await _upsertEntity(db, 'class_enrollments', response['enrollments'] ?? []);
    await _upsertEntity(db, 'assessments', response['assessments'] ?? []);
    await _upsertEntity(db, 'questions', response['questions'] ?? []);
    await _upsertEntity(
      db,
      'assessment_submissions',
      response['assessment_submissions'] ?? [],
    );
    await _upsertEntity(db, 'assignments', response['assignments'] ?? []);
    await _upsertEntity(
      db,
      'assignment_submissions',
      response['assignment_submissions'] ?? [],
    );
    await _upsertEntity(db, 'learning_materials', response['learning_materials'] ?? []);

    // Save sync metadata
    final expiryAt = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    await db.insert(
      'sync_metadata',
      {'key': 'last_sync_at', 'value': syncToken},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'sync_metadata',
      {'key': 'data_expiry_at', 'value': expiryAt},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return serverTime ?? syncToken;
  }

  /// Run delta sync on app restart
  /// Returns null if data_expired (caller should fall back to full sync)
  Future<String?> _runDeltaSync(String lastSyncAt, String? dataExpiryAt) async {
    // Get device ID
    final db = await _localDatabase.database;
    final deviceIdRows = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['device_id'],
    );
    final deviceId = deviceIdRows.isNotEmpty
        ? deviceIdRows.first['value'] as String
        : _generateAndStoreDeviceId(db);

    // Fetch deltas
    final response =
        await _syncRemoteDataSource.deltaSync(
      deviceId: deviceId,
      lastSyncAt: lastSyncAt,
      dataExpiryAt: dataExpiryAt,
    );

    // Check if data is expired
    if (response['status'] == 'data_expired') {
      return null; // Caller will fall back to full sync
    }

    final syncToken = response['sync_token'] as String?;
    final serverTime = response['server_time'] as String?;
    final deltas = response['deltas'] as Map<String, dynamic>?;

    if (syncToken == null || deltas == null) {
      throw Exception('Invalid delta sync response');
    }

    // Process deltas: upsert updated, delete removed
    await _processDeltaPayload(db, deltas);

    // Update sync metadata
    final expiryAt = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    await db.insert(
      'sync_metadata',
      {'key': 'last_sync_at', 'value': syncToken},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'sync_metadata',
      {'key': 'data_expiry_at', 'value': expiryAt},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return serverTime ?? syncToken;
  }

  /// Upsert records into a table
  Future<void> _upsertEntity(
    Database db,
    String tableName,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      await db.insert(
        tableName,
        {
          ...data,
          'sync_status': 'synced',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Process delta payload: upsert updated, soft-delete removed
  Future<void> _processDeltaPayload(
    Database db,
    Map<String, dynamic> deltas,
  ) async {
    final entityMap = {
      'classes': 'classes',
      'enrollments': 'class_enrollments',
      'assessments': 'assessments',
      'questions': 'questions',
      'assessment_submissions': 'assessment_submissions',
      'assignments': 'assignments',
      'assignment_submissions': 'assignment_submissions',
      'learning_materials': 'learning_materials',
    };

    for (final entry in entityMap.entries) {
      final entityKey = entry.key;
      final tableName = entry.value;
      final entityDeltas = deltas[entityKey] as Map<String, dynamic>?;

      if (entityDeltas == null) continue;

      // Upsert updated records
      final updated = entityDeltas['updated'] as List<dynamic>? ?? [];
      await _upsertEntity(db, tableName, updated);

      // Soft-delete removed records
      final deleted = entityDeltas['deleted'] as List<dynamic>? ?? [];
      for (final id in deleted) {
        await db.update(
          tableName,
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }
  }

  /// Generate and store a device ID
  String _generateAndStoreDeviceId(Database db) {
    final deviceId = const Uuid().v4();
    db.insert(
      'sync_metadata',
      {'key': 'device_id', 'value': deviceId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return deviceId;
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
      case 'admin_user':
      case 'users':
        return 'users';
      case 'activity_logs':
        return 'activity_logs';
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

  /// Handles a single file upload operation by calling the multipart endpoint directly.
  /// References pattern in: mobile/lib/data/datasources/remote/assignment_remote_datasource.dart
  Future<void> _handleFileUpload(SyncQueueEntry op) async {
    try {
      final payload      = op.payload;
      final localPath    = payload['local_path']    as String;
      final fileName     = payload['file_name']     as String;
      final submissionId = payload['submission_id'] as String?;
      final materialId   = payload['material_id']   as String?;

      if (submissionId != null) {
        await _syncRemoteDataSource.uploadSubmissionFile(
          submissionId: submissionId,
          localPath: localPath,
          fileName: fileName,
        );
      } else if (materialId != null) {
        await _syncRemoteDataSource.uploadMaterialFile(
          materialId: materialId,
          localPath: localPath,
          fileName: fileName,
        );
      }

      // Clean up staged file after successful upload
      try {
        final stagedFile = File(localPath);
        if (await stagedFile.exists()) {
          await stagedFile.delete();
        }
      } catch (cleanupError) {
        // Log but don't fail sync if cleanup fails
        print('Warning: Failed to cleanup staged file: $cleanupError');
      }

      await _syncQueue.markSucceeded(op.id);
    } catch (e) {
      await _syncQueue.markFailed(op.id, e.toString());
    }
  }

  /// Maps Dart SyncEntityType enum to server-expected snake_case string
  static String _entityTypeToServer(SyncEntityType type) {
    switch (type) {
      case SyncEntityType.assessmentSubmission: return 'assessment_submission';
      case SyncEntityType.assignmentSubmission: return 'assignment_submission';
      case SyncEntityType.classEntity:          return 'class';
      case SyncEntityType.learningMaterial:     return 'learning_material';
      case SyncEntityType.materialFile:         return 'material_file';
      case SyncEntityType.submissionFile:       return 'submission_file';
      case SyncEntityType.adminUser:            return 'admin_user';
      default: return type.name; // user, assessment, assignment, question
    }
  }

  /// Maps Dart SyncOperation enum to server-expected string
  static String _operationToServer(SyncOperation op) {
    if (op == SyncOperation.saveAnswers) return 'save_answers';
    if (op == SyncOperation.releaseResults) return 'release_results';
    if (op == SyncOperation.overrideAnswer) return 'override_answer';
    if (op == SyncOperation.addEnrollment) return 'add_enrollment';
    if (op == SyncOperation.removeEnrollment) return 'remove_enrollment';
    return op.name;
  }
}
