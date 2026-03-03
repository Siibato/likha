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

      // Refresh pending count after sync completes (should be 0 now)
      final finalPendingCount = await _syncQueue.getPendingCount();
      _updateState(
        phase: SyncPhase.succeeded,
        lastSyncAt: DateTime.now(),
        pendingCount: finalPendingCount,
      );
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
          'entity_type': entry.entityType.serverValue,
          'operation':   entry.operation.serverValue,
          'payload':     entry.payload,
        };
      }).toList();

      final response = await _syncRemoteDataSource.pushOperations(
        operations: operations,
      );

      try {
        await _processPushResults(response);
      } catch (e) {
        rethrow;
      }
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

        if (entityType == SyncEntityType.adminUser.serverValue && operation == 'create') {
          try {
            await db.delete(
              'users',
              where: 'id = ? AND sync_status = ?',
              whereArgs: ['', 'pending'],
            );
          } catch (e) {
            //
          }
        }

        // If this was a create operation, map local ID to server ID
        if (serverId != null && operation == 'create' && entry != null) {
          final localId = entry.payload['local_id'] as String?;
          if (localId != null) {
            idMappings.add(
              (entityType: entityType, localId: localId, serverId: serverId),
            );

            // Special handling for classes: update main ID from local UUID to server UUID
            if (entityType == SyncEntityType.classEntity.serverValue) {
              await db.update(
                'classes',
                {'id': serverId},
                where: 'id = ?',
                whereArgs: [localId],
              );

              // Update any pending enrollment operations that reference this class
              // (e.g., add_enrollment/remove_enrollment operations queued while class was offline)
              final pendingEnrollments = await db.query(
                'sync_queue',
                where: 'status = ? AND (operation = ? OR operation = ?) AND payload LIKE ?',
                whereArgs: [
                  'pending',
                  SyncOperation.addEnrollment.dbValue,
                  SyncOperation.removeEnrollment.dbValue,
                  '%"class_id":"$localId"%',
                ],
              );

              for (final entry in pendingEnrollments) {
                final payloadStr = entry['payload'] as String?;
                if (payloadStr != null) {
                  // Replace local class_id with server class_id in the payload
                  final updatedPayload = payloadStr.replaceAll('"class_id":"$localId"', '"class_id":"$serverId"');
                  await db.update(
                    'sync_queue',
                    {'payload': updatedPayload},
                    where: 'id = ?',
                    whereArgs: [entry['id']],
                  );
                }
              }
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

    // Extract the data wrapper (response structure: {success, status_code, data: {...}, error})
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('No data in full sync response');
    }

    final syncToken = data['sync_token'] as String?;
    final serverTime = data['server_time'] as String?;

    if (syncToken == null) {
      throw Exception('No sync_token in full sync response');
    }

    // Upsert all entity data
    final enrolledStudents = (data['enrolled_students'] as List?) ?? [];
    final userData = data['user'] as Map<String, dynamic>?;

    // Build studentMap for submission enrichment
    final studentMap = <String, dynamic>{};
    for (final s in enrolledStudents) {
      final student = s as Map<String, dynamic>;
      studentMap[student['id'] as String] = student;
    }

    await _upsertClasses(db, data['classes'] ?? []);
    await _upsertEnrolledStudents(db, enrolledStudents);
    await _upsertEnrollments(db, data['enrollments'] ?? [], enrolledStudents);
    await _upsertAssessments(db, data['assessments'] ?? []);
    await _upsertQuestions(db, data['questions'] ?? []);
    await _upsertAssessmentSubmissions(db, data['assessment_submissions'] ?? [], studentMap);
    await _upsertAssignments(db, data['assignments'] ?? []);
    await _upsertAssignmentSubmissions(db, data['assignment_submissions'] ?? [], studentMap);
    await _upsertLearningMaterials(db, data['learning_materials'] ?? []);

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
          'is_active': (userData['is_active'] == true) ? 1 : 0,
          'activated_at': userData['activated_at'],
          'created_at': userData['created_at'],
          'updated_at': userData['updated_at'] ?? userData['created_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_offline_mutation': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

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

  Future<void> _upsertClasses(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      await db.insert(
        'classes',
        {
          ...data,
          'teacher_username': data['teacher_username'] ?? '',
          'teacher_full_name': data['teacher_full_name'] ?? '',
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'is_archived': (data['is_archived'] == true) ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _upsertEnrollments(
    Database db,
    List<dynamic> enrollments,
    List<dynamic> enrolledStudents,
  ) async {
    // Build lookup map: student_id -> student data
    final studentMap = <String, Map<String, dynamic>>{};
    for (final s in enrolledStudents) {
      final student = s as Map<String, dynamic>;
      studentMap[student['id'] as String] = student;
    }

    for (final enrollment in enrollments) {
      final e = enrollment as Map<String, dynamic>;
      final studentId = e['student_id'] as String;
      final student = studentMap[studentId] ?? {};

      await db.insert(
        'class_enrollments',
        {
          'id': e['id'],
          'class_id': e['class_id'],
          'student_id': studentId,
          'username': student['username'] ?? '',
          'full_name': student['full_name'] ?? '',
          'role': student['role'] ?? 'student',
          'account_status': student['account_status'] ?? 'active',
          'is_active': (student['is_active'] == true) ? 1 : 0,
          'enrolled_at': e['enrolled_at'],
          'updated_at': e['enrolled_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
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
      final data = record as Map<String, dynamic>;
      // Only insert columns that exist in the users table
      await db.insert(
        'users',
        {
          'id': data['id'],
          'username': data['username'],
          'full_name': data['full_name'],
          'role': data['role'],
          'account_status': data['account_status'],
          'is_active': (data['is_active'] == true) ? 1 : 0,
          'activated_at': data['activated_at'],
          'created_at': data['created_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
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
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Explicit upsert handler for questions with proper field mapping
  /// CRITICAL: Preserves existing choices_json/correct_answers_json/enumeration_items_json
  /// from REST API cache path (server manifest doesn't include choices)
  Future<void> _upsertQuestions(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;

      // Preserve existing cached choices (choices come from REST API, not from sync)
      final existing = await db.query(
        'questions',
        columns: ['choices_json', 'correct_answers_json', 'enumeration_items_json'],
        where: 'id = ?',
        whereArgs: [data['id']],
      );
      final existingChoices = existing.isNotEmpty ? existing.first['choices_json'] : null;
      final existingAnswers = existing.isNotEmpty ? existing.first['correct_answers_json'] : null;
      final existingEnum = existing.isNotEmpty ? existing.first['enumeration_items_json'] : null;

      await db.insert(
        'questions',
        {
          'id': data['id'],
          'assessment_id': data['assessment_id'],
          'question_type': data['question_type'],
          'question_text': data['question_text'],
          'points': data['points'] ?? 0,
          'order_index': data['order_index'] ?? 0,
          'is_multi_select': (data['is_multi_select'] == true) ? 1 : 0,
          'choices_json': existingChoices,
          'correct_answers_json': existingAnswers,
          'enumeration_items_json': existingEnum,
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'deleted_at': data['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
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
          'due_at': data['due_at'],
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
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Explicit upsert handler for assessment submissions with student enrichment
  Future<void> _upsertAssessmentSubmissions(
    Database db,
    List<dynamic> records,
    Map<String, dynamic> studentMap,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      final student = studentMap[data['student_id']] ?? {};

      await db.insert(
        'assessment_submissions',
        {
          'id': data['id'],
          'assessment_id': data['assessment_id'],
          'student_id': data['student_id'],
          'student_name': (student['full_name'] as String?) ?? '',
          'student_username': (student['username'] as String?) ?? '',
          'started_at': data['started_at'] ?? DateTime.now().toIso8601String(),
          'submitted_at': data['submitted_at'],
          'auto_score': data['auto_score'] ?? 0,
          'final_score': data['final_score'] ?? 0,
          'is_submitted': (data['is_submitted'] == true) ? 1 : 0,
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'cached_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
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
          'cached_at': DateTime.now().toIso8601String(),
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
    // Handle classes separately (requires mobile-only defaults)
    final classesDeltas = deltas['classes'] as Map<String, dynamic>?;
    if (classesDeltas != null) {
      final updated = classesDeltas['updated'] as List<dynamic>? ?? [];
      await _upsertClasses(db, updated);

      final deleted = classesDeltas['deleted'] as List<dynamic>? ?? [];
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
      // For delta, students should already be in the users table
      for (final enrollment in updated) {
        final e = enrollment as Map<String, dynamic>;
        final studentId = e['student_id'] as String;

        // Look up student from local users table
        final studentRows = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [studentId],
        );
        final student = studentRows.isNotEmpty
            ? studentRows.first as Map<String, dynamic>
            : <String, dynamic>{};

        await db.insert(
          'class_enrollments',
          {
            'id': e['id'],
            'class_id': e['class_id'],
            'student_id': studentId,
            'username': student['username'] ?? '',
            'full_name': student['full_name'] ?? '',
            'role': student['role'] ?? 'student',
            'account_status': student['account_status'] ?? 'active',
            'is_active': student['is_active'] ?? 1,
            'enrolled_at': e['enrolled_at'],
            'updated_at': e['enrolled_at'],
            'cached_at': DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Hard-delete removed enrollments (student was unenrolled)
      final deleted = enrollmentDeltas['deleted'] as List<dynamic>? ?? [];
      for (final id in deleted) {
        await db.delete(
          'class_enrollments',
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
      await _upsertAssessments(db, updated);

      final deleted = assessmentDeltas['deleted'] as List<dynamic>? ?? [];
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
      await _upsertQuestions(db, updated);

      final deleted = questionDeltas['deleted'] as List<dynamic>? ?? [];
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
      await _upsertAssessmentSubmissions(db, updated, studentMap);

      final deleted = assessmentSubmissionDeltas['deleted'] as List<dynamic>? ?? [];
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
      await _upsertAssignments(db, updated);

      final deleted = assignmentDeltas['deleted'] as List<dynamic>? ?? [];
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
      await _upsertAssignmentSubmissions(db, updated, studentMap);

      final deleted = assignmentSubmissionDeltas['deleted'] as List<dynamic>? ?? [];
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
      await _upsertLearningMaterials(db, updated);

      final deleted = materialDeltas['deleted'] as List<dynamic>? ?? [];
      for (final id in deleted) {
        await db.update(
          'learning_materials',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    final enrolledStudentsDeltas = deltas['enrolled_students'] as Map<String, dynamic>?;
    if (enrolledStudentsDeltas != null) {
      final updated = enrolledStudentsDeltas['updated'] as List<dynamic>? ?? [];
      await _upsertEnrolledStudents(db, updated);

      // Note: We don't soft-delete users - they are reusable across contexts
      // (current user, enrolled students, search results)
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
      } catch (_) {
        // Log but don't fail sync if cleanup fails
      }

      await _syncQueue.markSucceeded(op.id);
    } catch (e) {
      await _syncQueue.markFailed(op.id, e.toString());
    }
  }

}
