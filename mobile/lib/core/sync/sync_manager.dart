import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_logger.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessment_remote_datasource.dart';
import 'package:likha/data/datasources/remote/sync_remote_datasource.dart';
import 'package:likha/data/models/sync/push_response_model.dart';
import 'package:likha/services/storage_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

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
    this._assessmentRemoteDataSource,
    this._assessmentLocalDataSource,
    this._log,
    this._storageService,
  );

  /// Start sync manager - listen for server reachability changes
  void start() {
    stop(); // cancel any existing subscription to prevent duplicates
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
    if (!await _storageService.isAuthenticated()) return;
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

      // Refresh pending count after sync completes (should be 0 now)
      final finalPendingCount = await _syncQueue.getPendingCount();
      _updateState(
        phase: SyncPhase.succeeded,
        lastSyncAt: DateTime.now(),
        pendingCount: finalPendingCount,
      );
    } catch (e, st) {
      final errorMsg = _formatError(e, st);
      _log.syncError(errorMsg);
      _updateState(
        phase: SyncPhase.failed,
        lastError: errorMsg,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Format error with stack trace for better debugging
  String _formatError(Object error, StackTrace stackTrace) {
    if (error is Exception) {
      return error.toString();
    }
    return 'Unexpected error: ${error.toString()}\n${stackTrace.toString()}';
  }

  Future<void> _outboundSync() async {
    final pending = await _syncQueue.getAllRetriable();
    if (pending.isEmpty) return;

    // Split uploads: material files run AFTER regular ops, others run FIRST
    final nonMaterialFileUploads = pending
        .where((e) => e.operation == SyncOperation.upload && e.entityType != SyncEntityType.materialFile)
        .toList();
    final materialFileUploads = pending
        .where((e) => e.operation == SyncOperation.upload && e.entityType == SyncEntityType.materialFile)
        .toList();
    final regularOps = pending
        .where((e) => e.operation != SyncOperation.upload)
        .toList();

    final opsByType = <String, int>{};
    for (final op in regularOps) {
      opsByType[op.entityType.serverValue] = (opsByType[op.entityType.serverValue] ?? 0) + 1;
    }

    _log.pushStarting(
      uploadOpsCount: nonMaterialFileUploads.length + materialFileUploads.length,
      regularOpsCount: regularOps.length,
      operationsByType: opsByType,
    );

    final pushStartTime = DateTime.now();

    // Step 1: Run non-material file uploads first (submission files, etc.)
    for (final op in nonMaterialFileUploads) {
      await _handleFileUpload(op);
    }

    // Step 2: Run all regular operations in one batch (no two-phase split)
    if (regularOps.isNotEmpty) {
      await _syncRegularBatch(regularOps, pushStartTime);
    }

    // Step 3: Run material file uploads AFTER regular ops (material now exists on server)
    for (final op in materialFileUploads) {
      await _handleFileUpload(op);
    }
  }

  /// Sync a batch of operations
  Future<void> _syncRegularBatch(List<SyncQueueEntry> regularOps, DateTime pushStartTime) async {
    _updateState(pendingCount: regularOps.length);

    final operations = regularOps.map((entry) {
      return {
        'id':          entry.id,
        'entity_type': entry.entityType.serverValue,
        'operation':   entry.operation.serverValue,
        'payload':     entry.payload,
      };
    }).toList();

    final response = await _syncRemoteDataSource.pushOperations(
      operations: operations,
    );

    try {
      await _processPushResults(response, pushStartTime);
    } catch (e) {
      rethrow;
    }
  }

  /// Process push results and update local state
  Future<void> _processPushResults(PushResponseModel response, DateTime startTime) async {
    final db = await _localDatabase.database;

    // Track success/failure by entity type for logging
    final successByType = <String, int>{};
    final failedByType = <String, int>{};

    for (final result in response.results) {
      final opId = result.id;
      final success = result.success;
      final serverId = result.serverId;
      final entityType = result.entityType;
      final operation = result.operation;

      // Log individual operation result
      _log.pushOperationResult(
        entityType: entityType,
        operation: operation,
        opId: opId,
        success: success,
        serverId: serverId,
        error: result.error,
      );

      if (success) {
        successByType[entityType] = (successByType[entityType] ?? 0) + 1;

        // Fetch entry BEFORE marking succeeded (entry is hard-deleted on succeed)
        final entry = await _syncQueue.getById(opId);

        // Minimal fallback: if server returned a different ID (class dedup edge case only),
        // update the local database to use the server's ID instead
        if (serverId != null && operation == 'create' && entry != null) {
          final payloadId = entry.payload['id'] as String?;
          if (payloadId != null && payloadId != serverId) {
            // Server returned different ID (likely due to class title dedup)
            // Update the entity table to use the server ID
            if (entityType == SyncEntityType.classEntity.serverValue) {
              await db.update(
                'classes',
                {'id': serverId},
                where: 'id = ?',
                whereArgs: [payloadId],
              );
            }
          }
        }

        // Mark as succeeded and remove from queue
        await _syncQueue.markSucceeded(opId);
      } else {
        failedByType[entityType] = (failedByType[entityType] ?? 0) + 1;

        // Mark as failed
        final error = result.error ?? 'Unknown error';
        await _syncQueue.markFailed(opId, error);
      }
    }

    // Log summary of push results
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _log.pushResults(
      successByType: successByType,
      failedByType: failedByType,
      idMappingsByType: const {},
      totalDuration: duration,
    );
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

    // STEP 0: Initialize progress
    _updateState(progress: 0.0, currentStep: 'Preparing Likha for you…');

    // STEP 1: Make base request (empty classIds) to get user, classes, enrollments, enrolled_students
    _updateState(currentStep: 'Fetching classes and enrollments…');

    final baseResponse = await _syncRemoteDataSource.fullSync(
      deviceId: deviceId,
      receiveTimeout: const Duration(seconds: 30),
    );

    _log.warn('Full sync response keys: ${baseResponse.keys.join(", ")}');

    final baseData = baseResponse['data'] as Map<String, dynamic>?;
    if (baseData == null) {
      _log.error('No data in full sync response', 'Response: $baseResponse');
      throw Exception('No data in full sync response. Response: $baseResponse');
    }

    final syncToken = baseData['sync_token'] as String?;
    final serverTime = baseData['server_time'] as String?;

    if (syncToken == null) {
      throw Exception('No sync_token in full sync response');
    }

    // Upsert base response data (user, classes, enrollments, enrolled_students)
    final enrolledStudents = (baseData['enrolled_students'] as List?) ?? [];
    final userData = baseData['user'] as Map<String, dynamic>?;

    // Track students per class
    final rawEnrollments = (baseData['enrollments'] as List?) ?? [];
    final studentsPerClassCount = <String, int>{};
    for (final e in rawEnrollments) {
      if (e is! Map<String, dynamic>) continue;
      final cid = e['class_id']?.toString();
      if (cid != null) studentsPerClassCount[cid] = (studentsPerClassCount[cid] ?? 0) + 1;
    }

    // Upsert all base response data sequentially (proper await ensures committed before verification)
    _log.warn('Starting base response data upsert (classes, enrollments, students)...');
    await _upsertClasses(db, baseData['classes'] ?? []);
    await _upsertEnrolledStudents(db, enrolledStudents);
    await _upsertEnrollments(db, baseData['enrollments'] ?? [], enrolledStudents);

    _log.baseResponse(
      classes: (baseData['classes'] as List?)?.length ?? 0,
      enrollments: rawEnrollments.length,
      students: enrolledStudents.length,
    );

    // Log per-class student counts
    final classes = (baseData['classes'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];
    for (final cls in classes) {
      final clsId = cls['id']?.toString() ?? '';
      _log.studentsPerClass(cls, studentsPerClassCount[clsId] ?? 0);
    }

    // Cache the logged-in user from sync response
    if (userData != null) {
      await db.insert(
        'users',
        {
          'id': userData['id'],
          'username': userData['username'],
          'full_name': userData['full_name'],
          'role': userData['role'],
          'account_status': userData['account_status'],
          'activated_at': userData['activated_at'],
          'created_at': userData['created_at'],
          'updated_at': userData['updated_at'] ?? userData['created_at'],
          'deleted_at': userData['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_offline_mutation': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // VERIFICATION: Check what was actually stored in SQLite (after all awaits complete)
    _log.warn('Starting SQLite verification for class_participants...');
    try {
      final countResult = await db.rawQuery('SELECT COUNT(*) FROM class_participants');
      _log.warn('Count query returned ${countResult.length} result row(s)');

      final totalRows = Sqflite.firstIntValue(countResult) ?? 0;
      _log.warn('Verified $totalRows total rows in class_participants');

      final byClassQuery = await db.rawQuery(
        'SELECT class_id, COUNT(*) as count FROM class_participants WHERE role = ? AND removed_at IS NULL GROUP BY class_id ORDER BY class_id',
        ['student'],
      );

      _log.warn('Per-class breakdown query returned ${byClassQuery.length} row(s)');

      final byClass = <String, int>{};
      for (final row in byClassQuery) {
        final classId = row['class_id']?.toString() ?? '?';
        var count = row['count'];
        final countInt = count is int ? count : (int.tryParse(count.toString()) ?? 0);
        byClass[classId] = countInt;
        _log.warn('  class_id $classId: $countInt students');
      }

      _log.sqliteVerification(totalClassParticipants: totalRows, participantsByClass: byClass);
      _log.warn('SQLite verification completed successfully');
    } catch (e) {
      _log.warn('SQLite verification failed: $e');
      _log.error('class_participants verification error', e.toString());
    }
    _log.warn('Base response data upsert completed');

    // STEP 2: Extract classes and create batches of 2
    final classesForBatching = (baseData['classes'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList() ?? [];
    final classBatches = <List<String>>[];
    final classMap = <String, String>{};
    for (final cls in classesForBatching) {
      final id = cls['id']?.toString();
      final title = cls['title'] as String?;
      if (id != null && id.isNotEmpty && title != null) {
        classMap[id] = title;
      }
    }

    for (int i = 0; i < classesForBatching.length; i += 2) {
      final batch = classesForBatching.skip(i).take(2)
          .map((c) => c['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      classBatches.add(batch);
    }

    _log.fullSyncStart(classesForBatching.length, classBatches.length);

    // STEP 3: Update progress to 0.1 and start batch loading
    _updateState(progress: 0.1, currentStep: 'Loading your classes…');

    // Build student map for submission enrichment
    final studentMap = <String, dynamic>{};
    for (final s in enrolledStudents) {
      if (s is! Map<String, dynamic>) continue;
      final id = s['id']?.toString();
      if (id != null && id.isNotEmpty) {
        studentMap[id] = s;
      }
    }

    // STEP 4: Iterate through batches with progress updates
    if (classBatches.isNotEmpty) {
      for (int batchIndex = 0; batchIndex < classBatches.length; batchIndex++) {
        final batch = classBatches[batchIndex];
        final progressBase = 0.1;
        final progressRange = 0.85;
        final batchProgress = progressBase + (progressRange * (batchIndex / classBatches.length));

        // Create step description with batch titles
        final batchTitles = batch.map((id) => classMap[id] ?? id).join(' & ');
        final currentStepText = 'Getting $batchTitles ready… (${batchIndex + 1}/${classBatches.length})';
        _updateState(progress: batchProgress, currentStep: currentStepText);

        _log.batchStart(batchIndex, classBatches.length, batch);

        // Make batch request with receiveTimeout
        final batchResponse = await _syncRemoteDataSource.fullSync(
          deviceId: deviceId,
          classIds: batch,
          receiveTimeout: const Duration(seconds: 30),
        );

        final batchData = batchResponse['data'] as Map<String, dynamic>?;
        if (batchData == null) {
          continue;
        }

        // Upsert all entities from batch response
        final assessments = batchData['assessments'] ?? [];
        final questions = batchData['questions'] ?? [];
        final assessmentSubmissions = batchData['assessment_submissions'] ?? [];
        final assignments = batchData['assignments'] ?? [];
        final assignmentSubmissions = batchData['assignment_submissions'] ?? [];
        final submissionFiles = batchData['submission_files'] ?? [];
        final learningMaterials = batchData['learning_materials'] ?? [];
        final materialFiles = batchData['material_files'] ?? [];
        final assessmentStatistics = batchData['assessment_statistics'] ?? [];
        final studentResults = batchData['student_results'] ?? [];

        // NEW: Extract enrolled_students and enrollments from batch (for full offline support)
        final batchEnrolledStudents = (batchData['enrolled_students'] as List?) ?? [];
        final batchEnrollments = (batchData['enrollments'] as List?) ?? [];

        _log.batchReceived(batchIndex, classBatches.length, {
          'assessments': assessments.length,
          'questions': questions.length,
          'assessment_submissions': assessmentSubmissions.length,
          'assignments': assignments.length,
          'assignment_submissions': assignmentSubmissions.length,
          'learning_materials': learningMaterials.length,
          'material_files': materialFiles.length,
          'submission_files': submissionFiles.length,
          'assessment_statistics': assessmentStatistics.length,
          'student_results': studentResults.length,
          'enrolled_students': batchEnrolledStudents.length,  // NEW: for offline support
          'enrollments': batchEnrollments.length,              // NEW: for offline support
        });

        // Log questions per assessment
        final questionsByAssessment = <String, int>{};
        for (final q in questions) {
          if (q is Map<String, dynamic>) {
            final assessmentId = q['assessment_id'] as String?;
            if (assessmentId != null) {
              questionsByAssessment[assessmentId] = (questionsByAssessment[assessmentId] ?? 0) + 1;
            }
          }
        }
        for (final assessment in assessments) {
          if (assessment is Map<String, dynamic>) {
            final assessmentId = assessment['id'] as String?;
            final title = assessment['title'] as String? ?? 'unknown';
            final qCount = questionsByAssessment[assessmentId] ?? 0;
            _log.questionsPerAssessment(title, assessmentId ?? '?', qCount);
          }
        }

        // NEW: Upsert batch enrolled_students and enrollments (for full offline support)
        await _upsertEnrolledStudents(db, batchEnrolledStudents);
        await _upsertEnrollments(db, batchEnrollments, batchEnrolledStudents);

        // Update in-memory studentMap with batch students so submissions can reference them
        for (final s in batchEnrolledStudents) {
          if (s is! Map<String, dynamic>) continue;
          final id = s['id']?.toString();
          if (id != null && id.isNotEmpty) {
            studentMap[id] = s;
          }
        }

        await _upsertAssessments(db, assessments);
        await _upsertQuestions(db, questions);
        await _upsertAssessmentSubmissions(db, assessmentSubmissions, studentMap);
        await _upsertAssignments(db, assignments);
        await _upsertAssignmentSubmissions(db, assignmentSubmissions, studentMap);
        await _upsertSubmissionFiles(db, submissionFiles);
        await _upsertLearningMaterials(db, learningMaterials);
        await _upsertMaterialFiles(db, materialFiles);

        _log.upsertSummary('assessment_statistics', assessmentStatistics.length);
        await _upsertStatistics(db, assessmentStatistics);
        _log.upsertSummary('student_results', studentResults.length);
        await _upsertStudentResults(db, studentResults);
      }
    }

    // STEP 5: Signal that entity data is now in the local DB
    _updateState(
      assessmentsReady: true,
      assignmentsReady: true,
      materialsReady: true,
    );

    // STEP 6: After all batches, set progress to 0.95 with "Almost there…"
    _updateState(progress: 0.95, currentStep: 'Almost there…');

    // STEP 7: Set progress to 1.0 with "Likha is ready!"
    _updateState(progress: 1.0, currentStep: 'Likha is ready!');

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

    // Extract the actual data from the wrapper
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      _log.error('No data in delta sync response', 'Response: $response');
      throw Exception('Invalid delta sync response: no data field');
    }

    // Check if data is expired
    if (response['status'] == 'data_expired') {
      return null; // Caller will fall back to full sync
    }

    final syncToken = data['sync_token'] as String?;
    final serverTime = data['server_time'] as String?;
    final deltas = data['deltas'] as Map<String, dynamic>?;

    if (syncToken == null || deltas == null) {
      _log.error('Missing fields in delta sync response', 'sync_token=$syncToken, deltas=$deltas');
      throw Exception('Invalid delta sync response: missing sync_token or deltas');
    }

    // Process deltas: upsert updated, delete removed
    await _processDeltaPayload(db, deltas);

    // Signal that delta data is now merged into local DB
    _updateState(
      assessmentsReady: true,
      assignmentsReady: true,
      materialsReady: true,
    );

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

  Future<void> _upsertClasses(
    Database db,
    List<dynamic> records,
  ) async {
    int successCount = 0;
    int failedCount = 0;

    for (final record in records) {
      try {
        if (record is! Map<String, dynamic>) continue;

        final teacherId = record['teacher_id'] ?? '';
        if (teacherId.isEmpty) {
          _log.warn('Class ${record['id']} has missing teacher_id', record);
        }

        await db.insert(
          'classes',
          {
            'id': record['id'],
            'title': record['title'],
            'description': record['description'],
            'teacher_id': teacherId,
            'teacher_username': record['teacher_username'] ?? '',
            'teacher_full_name': record['teacher_full_name'] ?? '',
            'is_archived': (record['is_archived'] == true) ? 1 : 0,
            'student_count': record['student_count'] ?? 0,
            'created_at': record['created_at'],
            'updated_at': record['updated_at'] ?? record['created_at'],
            'cached_at': DateTime.now().toIso8601String(),
            'sync_status': 'synced',
            'is_offline_mutation': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        successCount++;
      } catch (e) {
        failedCount++;
        _log.error('Failed to upsert class', e);
      }
    }

    _log.upsertSummary('classes', successCount);
    if (failedCount > 0) {
      _log.warn('Failed to upsert classes', failedCount);
    }

    await _populateTeacherInfoFromAccounts(db);
  }

  Future<void> _populateTeacherInfoFromAccounts(Database db) async {
    try {
      final classesNeedingTeacher = await db.query(
        'classes',
        where: 'teacher_username = ?',
        whereArgs: [''],
      );

      if (classesNeedingTeacher.isEmpty) return;

      _log.warn('Found ${classesNeedingTeacher.length} classes missing teacher info, attempting fallback');

      // Get cached user accounts
      final cachedUsers = await db.query('users');

      // Build teacher map: teacher_id -> (username, full_name)
      final teacherMap = <String, Map<String, String>>{};
      for (final user in cachedUsers) {
        final userId = user['id'] as String?;
        final username = user['username'] as String?;
        final fullName = user['full_name'] as String?;
        if (userId != null && username != null && fullName != null) {
          teacherMap[userId] = {
            'username': username,
            'full_name': fullName,
          };
        }
      }

      int updatedCount = 0;
      for (final cls in classesNeedingTeacher) {
        final teacherId = cls['teacher_id'] as String?;
        if (teacherId != null && teacherMap.containsKey(teacherId)) {
          final teacherInfo = teacherMap[teacherId]!;
          await db.update(
            'classes',
            {
              'teacher_username': teacherInfo['username'],
              'teacher_full_name': teacherInfo['full_name'],
            },
            where: 'id = ?',
            whereArgs: [cls['id']],
          );
          updatedCount++;
        }
      }
      _log.warn('Fallback populated $updatedCount/${classesNeedingTeacher.length} class teacher info');
    } catch (e, st) {
      _log.error('Error populating teacher info from accounts', '$e\n$st');
    }
  }

  Future<void> _upsertEnrollments(
    Database db,
    List<dynamic> enrollments,
    List<dynamic> enrolledStudents,
  ) async {
    // Build lookup map: user_id -> student data
    final studentMap = <String, Map<String, dynamic>>{};
    for (final s in enrolledStudents) {
      if (s is! Map<String, dynamic>) continue;
      final id = s['id']?.toString();
      if (id != null && id.isNotEmpty) {
        studentMap[id] = s;
      }
    }

    for (final enrollment in enrollments) {
      if (enrollment is! Map<String, dynamic>) continue;
      final e = enrollment;
      // Accept both user_id (new) and student_id (old) for backward compat
      final userId = (e['user_id'] ?? e['student_id'])?.toString();
      if (userId == null || userId.isEmpty) continue;
      final student = studentMap[userId] ?? {};

      await db.insert(
        'class_participants',
        {
          'id': e['id'],
          'local_id': e['id'],
          'class_id': e['class_id'],
          'user_id': userId,
          'username': student['username'] ?? '',
          'full_name': student['full_name'] ?? '',
          'role': 'student',
          'account_status': student['account_status'] ?? 'active',
          'joined_at': e['joined_at'] ?? e['enrolled_at'],
          'updated_at': e['joined_at'] ?? e['enrolled_at'],
          'removed_at': e['removed_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_offline_mutation': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// This distinguishes enrolled students from search-cached students
  Future<void> _upsertEnrolledStudents(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      if (record is! Map<String, dynamic>) continue;
      // Only insert columns that exist in the users table
      await db.insert(
        'users',
        {
          'id': record['id'],
          'username': record['username'],
          'full_name': record['full_name'],
          'role': record['role'],
          'account_status': record['account_status'],
          'activated_at': record['activated_at'],
          'created_at': record['created_at'],
          'updated_at': record['updated_at'] ?? record['created_at'],
          'deleted_at': record['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_offline_mutation': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Explicit upsert handler for assessments with proper field mapping
  Future<void> _upsertAssessments(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      await db.insert(
        'assessments',
        {
          'id': data['id'],
          'class_id': data['class_id'],
          'title': data['title'],
          'description': data['description'],
          'time_limit_minutes': data['time_limit_minutes'] ?? 0,
          'open_at': data['open_at'] ?? DateTime.now().toIso8601String(),
          'close_at': data['close_at'] ?? DateTime.now().toIso8601String(),
          'show_results_immediately': (data['show_results_immediately'] == true) ? 1 : 0,
          'results_released': (data['results_released'] == true) ? 1 : 0,
          'is_published': (data['is_published'] == true) ? 1 : 0,
          'total_points': data['total_points'] ?? 0,
          'question_count': data['question_count'] ?? 0,
          'submission_count': data['submission_count'] ?? 0,
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'deleted_at': data['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_offline_mutation': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Explicit upsert handler for questions with proper field mapping
  /// NEW: Server now sends nested choices/correct_answers/enumeration_items
  /// Backward compat: Preserves existing if server doesn't send them
  Future<void> _upsertQuestions(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;

      // Check if server sent nested data
      final serverSentChoices = data.containsKey('choices');
      final serverSentCorrectAnswers = data.containsKey('correct_answers');
      final serverSentEnumItems = data.containsKey('enumeration_items');

      // Resolve: use server value if sent, otherwise preserve existing
      String? choicesJson;
      String? correctAnswersJson;
      String? enumItemsJson;

      if (serverSentChoices || serverSentCorrectAnswers || serverSentEnumItems) {
        // Server sent at least some nested data; resolve each field
        if (serverSentChoices && data['choices'] is List && (data['choices'] as List).isNotEmpty) {
          choicesJson = jsonEncode(data['choices']);
        } else if (serverSentChoices) {
          choicesJson = null;
        } else {
          // Use existing
          final existing = await db.query('questions',
              columns: ['choices_json'], where: 'id = ?', whereArgs: [data['id']]);
          choicesJson = existing.isNotEmpty ? existing.first['choices_json'] as String? : null;
        }

        if (serverSentCorrectAnswers && data['correct_answers'] is List && (data['correct_answers'] as List).isNotEmpty) {
          correctAnswersJson = jsonEncode(data['correct_answers']);
        } else if (serverSentCorrectAnswers) {
          correctAnswersJson = null;
        } else {
          final existing = await db.query('questions',
              columns: ['correct_answers_json'], where: 'id = ?', whereArgs: [data['id']]);
          correctAnswersJson = existing.isNotEmpty ? existing.first['correct_answers_json'] as String? : null;
        }

        if (serverSentEnumItems && data['enumeration_items'] is List && (data['enumeration_items'] as List).isNotEmpty) {
          enumItemsJson = jsonEncode(data['enumeration_items']);
        } else if (serverSentEnumItems) {
          enumItemsJson = null;
        } else {
          final existing = await db.query('questions',
              columns: ['enumeration_items_json'], where: 'id = ?', whereArgs: [data['id']]);
          enumItemsJson = existing.isNotEmpty ? existing.first['enumeration_items_json'] as String? : null;
        }
      } else {
        // Server didn't send nested data; preserve existing (backward compat)
        final existing = await db.query(
          'questions',
          columns: ['choices_json', 'correct_answers_json', 'enumeration_items_json'],
          where: 'id = ?',
          whereArgs: [data['id']],
        );
        choicesJson = existing.isNotEmpty ? existing.first['choices_json'] as String? : null;
        correctAnswersJson = existing.isNotEmpty ? existing.first['correct_answers_json'] as String? : null;
        enumItemsJson = existing.isNotEmpty ? existing.first['enumeration_items_json'] as String? : null;
      }

      await db.insert(
        'questions',
        {
          'id': data['id'],
          'local_id': data['id'],
          'assessment_id': data['assessment_id'],
          'question_type': data['question_type'],
          'question_text': data['question_text'],
          'points': data['points'] ?? 0,
          'order_index': data['order_index'] ?? 0,
          'is_multi_select': (data['is_multi_select'] == true) ? 1 : 0,
          'choices_json': choicesJson,
          'correct_answers_json': correctAnswersJson,
          'enumeration_items_json': enumItemsJson,
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'deleted_at': data['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_offline_mutation': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Explicit upsert handler for assignments with proper field mapping
  Future<void> _upsertAssignments(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      await db.insert(
        'assignments',
        {
          'id': data['id'],
          'class_id': data['class_id'],
          'title': data['title'],
          'instructions': data['instructions'],
          'total_points': data['total_points'] ?? 0,
          'submission_type': data['submission_type'] ?? 'file',
          'allowed_file_types': data['allowed_file_types'],
          'max_file_size_mb': data['max_file_size_mb'],
          'due_at': data['due_at'] ?? '',
          'submission_status': data['submission_status'],
          'submission_id': data['submission_id'],
          'score': data['score'],
          'is_published': (data['is_published'] == true) ? 1 : 0,
          'submission_count': data['submission_count'] ?? 0,
          'graded_count': data['graded_count'] ?? 0,
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'deleted_at': data['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Explicit upsert handler for learning materials with proper field mapping
  Future<void> _upsertLearningMaterials(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      await db.insert(
        'learning_materials',
        {
          'id': data['id'],
          'class_id': data['class_id'],
          'title': data['title'],
          'description': data['description'],
          'content_text': data['content_text'],
          'order_index': data['order_index'] ?? 0,
          'file_count': data['file_count'] ?? 0,
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'deleted_at': data['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_offline_mutation': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Explicit upsert handler for assessment submissions with nested answers
  Future<void> _upsertAssessmentSubmissions(
    Database db,
    List<dynamic> records,
    Map<String, dynamic> studentMap,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      final id = data['id'] as String?;
      final serverIsSubmitted = data['is_submitted'] == true;

      // ✅ Guard: never let the server un-submit a locally-submitted pending row.
      // When sync_status='pending', the student submitted offline and the op hasn't
      // reached the server yet. The server's stale is_submitted=false must NOT
      // overwrite local is_submitted=1.
      // When server confirms is_submitted=true (after outbound sync), the server
      // value matches local — the guard condition is false → REPLACE proceeds normally.
      if (id != null && !serverIsSubmitted) {
        final existing = await db.query(
          'assessment_submissions',
          columns: ['is_submitted', 'sync_status'],
          where: 'id = ?',
          whereArgs: [id],
        );
        if (existing.isNotEmpty) {
          final localIsSubmitted = (existing.first['is_submitted'] as int?) == 1;
          final localSyncStatus = existing.first['sync_status'] as String?;
          if (localIsSubmitted && localSyncStatus == 'pending') {
            // Local has submitted state, server has stale not-submitted state → skip
            continue;
          }
        }
      }

      final student = studentMap[data['student_id']] ?? {};

      final answersJson = data.containsKey('answers') && data['answers'] != null
          ? jsonEncode(data['answers'] as List<dynamic>)
          : null;

      await db.insert(
        'assessment_submissions',
        {
          'id': data['id'],
          'local_id': data['id'],
          'assessment_id': data['assessment_id'],
          'student_id': data['student_id'],
          'student_name': (student['full_name'] as String?) ?? '',
          'student_username': (student['username'] as String?) ?? '',
          'started_at': data['started_at'] ?? DateTime.now().toIso8601String(),
          'submitted_at': data['submitted_at'],
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
          'auto_score': data['auto_score'] ?? 0,
          'final_score': data['final_score'] ?? 0,
          'is_submitted': (data['is_submitted'] == true) ? 1 : 0,
          'answers_json': answersJson,
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'deleted_at': data['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_offline_mutation': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Explicit upsert handler for assignment submissions with student enrichment
  Future<void> _upsertAssignmentSubmissions(
    Database db,
    List<dynamic> records,
    Map<String, dynamic> studentMap,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      final student = studentMap[data['student_id']] ?? {};

      await db.insert(
        'assignment_submissions',
        {
          'id': data['id'],
          'assignment_id': data['assignment_id'],
          'student_id': data['student_id'],
          'student_name': (student['full_name'] as String?) ?? '',
          'status': data['status'] ?? 'pending',
          'text_content': data['text_content'],
          'submitted_at': data['submitted_at'],
          'is_late': (data['is_late'] == true) ? 1 : 0,
          'score': data['score'],
          'feedback': data['feedback'],
          'graded_at': data['graded_at'],
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'deleted_at': data['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_offline_mutation': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// NEW: Upsert material files metadata (no binary data)
  Future<void> _upsertMaterialFiles(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;

      // Preserve local cache state (is_cached, local_path, is_compressed) if row exists
      final existing = await db.query(
        'material_files',
        columns: ['is_cached', 'local_path', 'is_compressed'],
        where: 'id = ?',
        whereArgs: [data['id']],
      );

      if (existing.isEmpty) {
        await db.insert(
          'material_files',
          {
            'id': data['id'],
            'local_id': data['id'],
            'material_id': data['material_id'],
            'file_name': data['file_name'],
            'file_type': data['file_type'],
            'file_size': data['file_size'] ?? 0,
            'uploaded_at': data['uploaded_at'] ?? DateTime.now().toIso8601String(),
            'local_path': null,
            'is_cached': 0,
            'is_compressed': 0,
            'deleted_at': null,
            'cached_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } else {
        // Only update server-side metadata — preserve local cache state
        await db.update(
          'material_files',
          {
            'file_name': data['file_name'],
            'file_type': data['file_type'],
            'file_size': data['file_size'] ?? 0,
            'uploaded_at': data['uploaded_at'] ?? DateTime.now().toIso8601String(),
            'cached_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [data['id']],
        );
      }
    }
  }

  /// NEW: Upsert submission files metadata (no binary data)
  Future<void> _upsertSubmissionFiles(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;

      final existing = await db.query(
        'submission_files',
        columns: ['is_local_only', 'local_path'],
        where: 'id = ?',
        whereArgs: [data['id']],
      );

      if (existing.isEmpty) {
        await db.insert(
          'submission_files',
          {
            'id': data['id'],
            'local_id': data['id'],
            'submission_id': data['submission_id'],
            'file_name': data['file_name'],
            'file_type': data['file_type'],
            'file_size': data['file_size'] ?? 0,
            'uploaded_at': data['uploaded_at'] ?? DateTime.now().toIso8601String(),
            'local_path': null,
            'is_local_only': 0,
            'deleted_at': null,
            'cached_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } else {
        // Only update if it's a server-synced file (not a locally-staged pending upload)
        final isLocalOnly = (existing.first['is_local_only'] as int?) == 1;
        if (!isLocalOnly) {
          await db.update(
            'submission_files',
            {
              'file_name': data['file_name'],
              'file_type': data['file_type'],
              'file_size': data['file_size'] ?? 0,
              'uploaded_at': data['uploaded_at'] ?? DateTime.now().toIso8601String(),
              'cached_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ? AND is_local_only = 0',
            whereArgs: [data['id']],
          );
        }
      }
    }
  }

  /// NEW: Upsert assessment statistics cache
  Future<void> _upsertStatistics(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      final assessmentId = data['assessment_id'] as String?;
      _log.upsertRecord('assessment_statistics', assessmentId ?? '?');
      await db.insert(
        'assessment_statistics_cache',
        {
          'assessment_id': data['assessment_id'],
          'statistics_json': jsonEncode(data),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// NEW: Upsert student results cache
  Future<void> _upsertStudentResults(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      final submissionId = data['submission_id'] as String?;
      _log.upsertRecord('student_results', submissionId ?? '?');
      await db.insert(
        'student_results_cache',
        {
          'submission_id': data['submission_id'],
          'results_json': jsonEncode(data),
          'cached_at': DateTime.now().toIso8601String(),
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
    final updatedCounts = <String, int>{};
    final deletedCounts = <String, int>{};

    // Handle classes separately (requires mobile-only defaults)
    final classesDeltas = deltas['classes'] as Map<String, dynamic>?;
    if (classesDeltas != null) {
      final updated = classesDeltas['updated'] as List<dynamic>? ?? [];
      await _upsertClasses(db, updated);
      updatedCounts['classes'] = updated.length;

      final deleted = classesDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['classes'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'classes',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle enrollments separately (requires student data lookup)
    final enrollmentDeltas = deltas['enrollments'] as Map<String, dynamic>?;
    if (enrollmentDeltas != null) {
      final updated = enrollmentDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['enrollments'] = updated.length;
      // For delta, students should already be in the users table
      for (final enrollment in updated) {
        final e = enrollment as Map<String, dynamic>;
        // Accept both user_id (new) and student_id (old) for backward compat
        final userId = (e['user_id'] ?? e['student_id']) as String;

        // Look up student from local users table
        final studentRows = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
        );
        final student = studentRows.isNotEmpty
            ? studentRows.first as Map<String, dynamic>
            : <String, dynamic>{};

        await db.insert(
          'class_participants',
          {
            'id': e['id'],
            'local_id': e['id'],
            'class_id': e['class_id'],
            'user_id': userId,
            'username': student['username'] ?? '',
            'full_name': student['full_name'] ?? '',
            'role': 'student',
            'account_status': student['account_status'] ?? 'active',
            'joined_at': e['joined_at'] ?? e['enrolled_at'],
            'updated_at': e['joined_at'] ?? e['enrolled_at'],
            'removed_at': null,
            'cached_at': DateTime.now().toIso8601String(),
            'sync_status': 'synced',
            'is_offline_mutation': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Soft-delete removed enrollments (student was unenrolled)
      final deleted = enrollmentDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['enrollments'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'class_participants',
          {'removed_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Build student map from local cache for submission enrichment
    final cachedUsers = await db.query('users');
    final studentMap = <String, dynamic>{};
    for (final u in cachedUsers) {
      studentMap[u['id'] as String] = u;
    }

    // Handle assessments separately (requires explicit field mapping)
    final assessmentDeltas = deltas['assessments'] as Map<String, dynamic>?;
    if (assessmentDeltas != null) {
      final updated = assessmentDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['assessments'] = updated.length;
      await _upsertAssessments(db, updated);

      final deleted = assessmentDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['assessments'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'assessments',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle questions separately (preserves cached choices)
    final questionDeltas = deltas['questions'] as Map<String, dynamic>?;
    if (questionDeltas != null) {
      final updated = questionDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['questions'] = updated.length;
      await _upsertQuestions(db, updated);

      final deleted = questionDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['questions'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'questions',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle assessment submissions separately (requires student enrichment)
    final assessmentSubmissionDeltas = deltas['assessment_submissions'] as Map<String, dynamic>?;
    if (assessmentSubmissionDeltas != null) {
      final updated = assessmentSubmissionDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['assessment_submissions'] = updated.length;
      await _upsertAssessmentSubmissions(db, updated, studentMap);

      final deleted = assessmentSubmissionDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['assessment_submissions'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'assessment_submissions',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle assignments separately (requires explicit field mapping)
    final assignmentDeltas = deltas['assignments'] as Map<String, dynamic>?;
    if (assignmentDeltas != null) {
      final updated = assignmentDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['assignments'] = updated.length;
      await _upsertAssignments(db, updated);

      final deleted = assignmentDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['assignments'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'assignments',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle assignment submissions separately (requires student enrichment)
    final assignmentSubmissionDeltas = deltas['assignment_submissions'] as Map<String, dynamic>?;
    if (assignmentSubmissionDeltas != null) {
      final updated = assignmentSubmissionDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['assignment_submissions'] = updated.length;
      await _upsertAssignmentSubmissions(db, updated, studentMap);

      final deleted = assignmentSubmissionDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['assignment_submissions'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'assignment_submissions',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle learning materials separately (requires explicit field mapping)
    final materialDeltas = deltas['learning_materials'] as Map<String, dynamic>?;
    if (materialDeltas != null) {
      final updated = materialDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['learning_materials'] = updated.length;
      await _upsertLearningMaterials(db, updated);

      final deleted = materialDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['learning_materials'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'learning_materials',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // NEW: Handle material files delta
    final materialFilesDeltas = deltas['material_files'] as Map<String, dynamic>?;
    if (materialFilesDeltas != null) {
      final updated = materialFilesDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['material_files'] = updated.length;
      await _upsertMaterialFiles(db, updated);

      final deleted = materialFilesDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['material_files'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'material_files',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // NEW: Handle submission files delta
    final submissionFilesDeltas = deltas['submission_files'] as Map<String, dynamic>?;
    if (submissionFilesDeltas != null) {
      final updated = submissionFilesDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['submission_files'] = updated.length;
      await _upsertSubmissionFiles(db, updated);

      final deleted = submissionFilesDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['submission_files'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'submission_files',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ? AND is_local_only = 0',
          whereArgs: [id as String],
        );
      }
    }

    final enrolledStudentsDeltas = deltas['enrolled_students'] as Map<String, dynamic>?;
    if (enrolledStudentsDeltas != null) {
      final updated = enrolledStudentsDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['enrolled_students'] = updated.length;
      await _upsertEnrolledStudents(db, updated);

      // Note: We don't soft-delete users - they are reusable across contexts
      // (current user, enrolled students, search results)
    }

    _log.deltaSync(updatedCounts: updatedCounts, deletedCounts: deletedCounts);
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

  /// Warm-up statistics cache for first 30 assessments
  // COMMENTED OUT: Unused - no callers found
  // void _warmUpStatisticsCache() {
  //   Future.microtask(() async {
  //     try {
  //       final db = await _localDatabase.database;
  //       final assessments = await db.query(
  //         'assessments',
  //         limit: 30,
  //         orderBy: 'created_at DESC',
  //       );
  //       for (final assessment in assessments) {
  //         final assessmentId = assessment['id'] as String;
  //         try {
  //           final result = await _assessmentRemoteDataSource.getStatistics(
  //             assessmentId: assessmentId,
  //           );
  //           await _assessmentLocalDataSource.cacheStatistics(result);
  //         } catch (_) {
  //           // Silently fail — warm-up is non-critical
  //         }
  //       }
  //     } catch (_) {
  //       // Silently fail
  //     }
  //   });
  // }

  /// Warm-up student results cache for released assessments
  // COMMENTED OUT: Unused - no callers found
  // void _warmUpStudentResultsCache() {
  //   Future.microtask(() async {
  //     try {
  //       final db = await _localDatabase.database;
  //       final releasedAssessments = await db.query(
  //         'assessments',
  //         where: '(results_released = 1 OR show_results_immediately = 1)',
  //         limit: 30,
  //       );
  //       final releasedIds = releasedAssessments
  //           .map((a) => a['id'] as String)
  //           .toSet();
  //
  //       final submissions = await db.query(
  //         'assessment_submissions',
  //         where: 'is_submitted = 1',
  //         limit: 30,
  //       );
  //
  //       for (final submission in submissions) {
  //         final assessmentId = submission['assessment_id'] as String;
  //         if (!releasedIds.contains(assessmentId)) continue;
  //
  //         final submissionId = submission['id'] as String;
  //         try {
  //           final result = await _assessmentRemoteDataSource.getStudentResults(
  //             submissionId: submissionId,
  //           );
  //           await _assessmentLocalDataSource.cacheStudentResults(result);
  //         } catch (_) {
  //           // Silently fail — warm-up is non-critical
  //         }
  //       }
  //     } catch (_) {
  //       // Silently fail
  //     }
  //   });
  // }

  /// Handles a single file upload operation by calling the multipart endpoint directly.
  /// References pattern in: mobile/lib/data/datasources/remote/assignment_remote_datasource.dart
  /// For material files, looks up correct (reconciled) material_id from DB instead of using payload.
  Future<void> _handleFileUpload(SyncQueueEntry op) async {
    try {
      final payload      = op.payload;
      final localPath    = payload['local_path']    as String;
      final fileName     = payload['file_name']     as String;
      final fileId       = payload['file_id']       as String?;
      final submissionId = payload['submission_id'] as String?;
      var materialId     = payload['material_id']   as String?;

      // For material file uploads, look up the correct (reconciled) material_id from DB
      if (materialId != null && fileId != null) {
        try {
          final db = await _localDatabase.database;
          final rows = await db.query(
            'material_files',
            columns: ['material_id'],
            where: 'id = ?',
            whereArgs: [fileId],
          );
          if (rows.isNotEmpty) {
            materialId = rows.first['material_id'] as String?;
          }
        } catch (_) {
          // If DB lookup fails, fall back to payload value
        }
      }

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
      } catch (_) {
        // Log but don't fail sync if cleanup fails
      }

      await _syncQueue.markSucceeded(op.id);
    } catch (e) {
      await _syncQueue.markFailed(op.id, e.toString());
    }
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
