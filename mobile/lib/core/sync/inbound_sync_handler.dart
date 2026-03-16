import 'dart:convert';

import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_logger.dart';
import 'package:likha/core/sync/sync_state.dart';
import 'package:likha/core/sync/sync_upsert_helpers.dart';
import 'package:likha/data/datasources/remote/sync_remote_datasource.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class InboundSyncHandler {
  final SyncRemoteDataSource _syncRemoteDataSource;
  final LocalDatabase _localDatabase;
  final SyncLogger _log;
  final SyncUpsertHelpers _upsertHelpers;
  final void Function({
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
  }) _updateState;

  InboundSyncHandler(
    this._syncRemoteDataSource,
    this._localDatabase,
    this._log,
    this._upsertHelpers,
    this._updateState,
  );

  /// INBOUND SYNC: Fetch server changes (full or delta)
  /// Returns server time to use for last_sync_at
  Future<String?> inboundSync() async {
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
      return await runFullSync();
    } else {
      // APP RESTART: delta sync
      final deltaResult = await runDeltaSync(lastSyncAt, dataExpiryAt);
      if (deltaResult == null) {
        // data_expired → fall back to full sync
        return await runFullSync();
      }
      return deltaResult;
    }
  }

  /// Run full sync on first login
  Future<String?> runFullSync() async {
    // Get device ID (or generate and store)
    final db = await _localDatabase.database;
    final deviceIdRows = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['device_id'],
    );
    final deviceId = deviceIdRows.isNotEmpty
        ? deviceIdRows.first['value'] as String
        : generateAndStoreDeviceId(db);

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
    var enrolledStudents = (baseData['enrolled_students'] as List?) ?? [];
    final userData = baseData['user'] as Map<String, dynamic>?;

    // Ensure current user is always in the list (may not be in enrolled_students if only teacher enrolled them)
    if (userData != null && enrolledStudents.every((s) => (s as Map<String, dynamic>?)?['id'] != userData['id'])) {
      enrolledStudents = [userData, ...enrolledStudents];
    }

    // Track students per class
    final rawEnrollments = (baseData['enrollments'] as List?) ?? [];
    final studentsPerClassCount = <String, int>{};
    for (final e in rawEnrollments) {
      if (e is! Map<String, dynamic>) continue;
      final cid = e['class_id']?.toString();
      if (cid != null) studentsPerClassCount[cid] = (studentsPerClassCount[cid] ?? 0) + 1;
    }

    // Cache the logged-in user from sync response (BEFORE enrollment upserts to avoid CASCADE DELETE)
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
          'needs_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Upsert all base response data sequentially (proper await ensures committed before verification)
    _log.warn('Starting base response data upsert (classes, enrollments, students)...');
    await _upsertHelpers.upsertClasses(db, baseData['classes'] ?? []);
    await _upsertHelpers.upsertEnrolledStudents(db, enrolledStudents);
    await _upsertHelpers.upsertEnrollments(db, baseData['enrollments'] ?? [], enrolledStudents);
    await _upsertHelpers.recalculateClassStudentCounts(db);

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

    // VERIFICATION: Check what was actually stored in SQLite (after all awaits complete)
    _log.warn('Starting SQLite verification for class_participants...');
    try {
      final countResult = await db.rawQuery('SELECT COUNT(*) FROM class_participants');
      _log.warn('Count query returned ${countResult.length} result row(s)');

      final totalRows = Sqflite.firstIntValue(countResult) ?? 0;
      _log.warn('Verified $totalRows total rows in class_participants');

      final byClassQuery = await db.rawQuery(
        'SELECT class_id, COUNT(*) as count FROM class_participants WHERE removed_at IS NULL GROUP BY class_id ORDER BY class_id',
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
        await _upsertHelpers.upsertEnrolledStudents(db, batchEnrolledStudents);
        await _upsertHelpers.upsertEnrollments(db, batchEnrollments, batchEnrolledStudents);

        // Update in-memory studentMap with batch students so submissions can reference them
        for (final s in batchEnrolledStudents) {
          if (s is! Map<String, dynamic>) continue;
          final id = s['id']?.toString();
          if (id != null && id.isNotEmpty) {
            studentMap[id] = s;
          }
        }

        await _upsertHelpers.upsertAssessments(db, assessments);
        await _upsertHelpers.upsertQuestions(db, questions);
        await _upsertHelpers.upsertAssessmentSubmissions(db, assessmentSubmissions, studentMap);
        await _upsertHelpers.upsertAssignments(db, assignments);
        await _upsertHelpers.upsertAssignmentSubmissions(db, assignmentSubmissions, studentMap);
        await _upsertHelpers.upsertSubmissionFiles(db, submissionFiles);
        await _upsertHelpers.upsertLearningMaterials(db, learningMaterials);
        await _upsertHelpers.upsertMaterialFiles(db, materialFiles);

        // NOTE: assessment_statistics_cache is still skipped (no use case), but student_results_cache now exists
        _log.warn(
          'Skipping upsert of ${assessmentStatistics.length} assessment_statistics (table not in schema)',
        );

        // Write student_results to cache
        if (studentResults.isNotEmpty) {
          await db.transaction((txn) async {
            for (final result in studentResults) {
              try {
                final data = result as Map<String, dynamic>;
                final submissionId = data['submission_id']?.toString();
                if (submissionId == null || submissionId.isEmpty) {
                  _log.warn('Student result missing submission_id, skipping');
                  continue;
                }

                final now = DateTime.now().toIso8601String();
                await txn.insert(
                  'student_results_cache',
                  {
                    'submission_id': submissionId,
                    'results_json': jsonEncode(data),
                    'cached_at': now,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              } catch (e) {
                _log.warn('Failed to cache student result: $e');
              }
            }
          });
          _log.upsertSummary('student_results_cache', studentResults.length);
        }
      }
    }

    await _upsertHelpers.recalculateClassStudentCounts(db);

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
  Future<String?> runDeltaSync(String lastSyncAt, String? dataExpiryAt) async {
    // Get device ID
    final db = await _localDatabase.database;
    final deviceIdRows = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['device_id'],
    );
    final deviceId = deviceIdRows.isNotEmpty
        ? deviceIdRows.first['value'] as String
        : generateAndStoreDeviceId(db);

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
    await _upsertHelpers.processDeltaPayload(db, deltas);
    await _upsertHelpers.recalculateClassStudentCounts(db);

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

  /// Generate and store a device ID
  String generateAndStoreDeviceId(Database db) {
    final deviceId = const Uuid().v4();
    db.insert(
      'sync_metadata',
      {'key': 'device_id', 'value': deviceId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return deviceId;
  }
}
