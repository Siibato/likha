import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/core/sync/sync_semaphore.dart';
import 'package:likha/core/sync/sync_state.dart';
import 'package:likha/core/sync/sync_upsert_helpers.dart';
import 'package:likha/data/datasources/remote/sync/sync_remote_datasource.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

class InboundSyncHandler {
  final SyncRemoteDataSource _syncRemoteDataSource;
  final LocalDatabase _localDatabase;
  final SyncLogger _log;
  final SyncUpsertHelpers _upsertHelpers;
  final SyncStateUpdater _updateState;
  final DataEventBus _dataEventBus;

  InboundSyncHandler(
    this._syncRemoteDataSource,
    this._localDatabase,
    this._log,
    this._upsertHelpers,
    this._updateState,
    this._dataEventBus,
  );

  /// INBOUND SYNC: Fetch server changes (full or delta)
  /// Returns server time to use for last_sync_at
  Future<String?> inboundSync() async {
    final db = await _localDatabase.database;

    // Check for last_sync_at
    final rows = await db.query(
      DbTables.syncMetadata,
      where: '${SyncMetadataCols.key} = ?',
      whereArgs: [DbValues.metaLastSyncAt],
    );
    final lastSyncAt = rows.isNotEmpty ? rows.first[SyncMetadataCols.value] as String? : null;

    final expiryRows = await db.query(
      DbTables.syncMetadata,
      where: '${SyncMetadataCols.key} = ?',
      whereArgs: [DbValues.metaDataExpiryAt],
    );
    final dataExpiryAt = expiryRows.isNotEmpty ? expiryRows.first[SyncMetadataCols.value] as String? : null;

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
    final deviceId = await _getOrCreateDeviceId(db);

    // STEP 0: Initialize progress
    _updateState(progress: 0.0, currentStep: 'Preparing Likha for you…');

    // STEP 1: Make base request (empty classIds) to get user, classes, enrollments, enrolled_students
    _updateState(currentStep: 'Fetching classes and enrollments…');

    final baseResponse = await _syncRemoteDataSource.fullSync(
      deviceId: deviceId,
      receiveTimeout: const Duration(seconds: 30),
    );

    _log.warn('Full sync response received');

    final syncToken = baseResponse.syncToken;
    final serverTime = baseResponse.serverTime;

    // Upsert base response data (user, classes, enrollments, enrolled_students)
    var participantUsers = <Map<String, dynamic>>[];
    final userData = baseResponse.user ?? <String, dynamic>{};
    final enrolledStudentsData = baseResponse.enrolledStudents ?? <List<Map<String, dynamic>>>[];

    // Track students per class and collect unique user_ids
    final rawParticipants = baseResponse.enrollments;
    final studentsPerClassCount = <String, int>{};
    final uniqueUserIds = <String>{};
    for (final e in rawParticipants) {
      final cid = e['class_id']?.toString();
      final uid = (e['user_id'] ?? e['student_id'])?.toString();
      if (cid != null) studentsPerClassCount[cid] = (studentsPerClassCount[cid] ?? 0) + 1;
      if (uid != null && uid.isNotEmpty) uniqueUserIds.add(uid);
    }

    // Upsert all base response data in a single transaction (atomic + fast)
    _log.warn('Starting base response data upsert (classes, enrollments, students)...');
    await db.transaction((txn) async {
      // Cache the logged-in user from sync response (BEFORE enrollment upserts to avoid CASCADE DELETE)
      if (userData.isNotEmpty) {
        await _upsertHelpers.upsertCurrentUser(txn, userData);
        participantUsers.add(userData);
        uniqueUserIds.remove(userData['id']?.toString()); // Remove already upserted user
      }

      // Upsert enrolled students from sync response
      if (enrolledStudentsData.isNotEmpty) {
        final studentsList = enrolledStudentsData.cast<Map<String, dynamic>>();
        await _upsertHelpers.upsertEnrolledStudents(txn, studentsList);
        participantUsers.addAll(studentsList);
        // Remove upserted users from uniqueUserIds set
        for (final student in studentsList) {
          final uid = student['id']?.toString();
          if (uid != null) uniqueUserIds.remove(uid);
        }
      }

      await _upsertHelpers.upsertClasses(txn, baseResponse.classes);
      await _upsertHelpers.upsertEnrolledStudents(txn, participantUsers);
      await _upsertHelpers.upsertParticipants(txn, baseResponse.enrollments, participantUsers);
      await _upsertHelpers.recalculateClassStudentCounts(txn);
      await _upsertHelpers.upsertActivityLogs(txn, baseResponse.activityLogs);

      // Upsert school settings from sync response (if present)
      if (baseResponse.schoolSettings != null) {
        await _upsertHelpers.upsertSchoolSettings(txn, [baseResponse.schoolSettings!]);
      }
    });

    _log.baseResponse(
      classes: baseResponse.classes.length,
      participants: rawParticipants.length,
      students: participantUsers.length,
    );

    // Log per-class student counts
    final classes = baseResponse.classes.whereType<Map<String, dynamic>>().toList();
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
    final classesForBatching = baseResponse.classes
        .whereType<Map<String, dynamic>>()
        .toList();
    final classBatches = <List<String>>[];
    final classMap = <String, String>{};
    for (final cls in classesForBatching) {
      final id = cls['id']?.toString();
      final title = cls['title'] as String?;
      if (id != null && id.isNotEmpty && title != null) {
        classMap[id] = title;
      }
    }

    for (int i = 0; i < classesForBatching.length; i += 4) {
      final batch = classesForBatching.skip(i).take(4)
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
    for (final s in participantUsers) {
      final id = s['id']?.toString();
      if (id != null && id.isNotEmpty) {
        studentMap[id] = s;
      }
    }

    // STEP 4: Fetch and upsert entity batches
    final needsEntityBatches = baseResponse.syncPlan?.needsEntityBatches ?? true;

    if (needsEntityBatches && classBatches.isNotEmpty) {
      // Fetch all batches concurrently with bounded concurrency
      final semaphore = SyncSemaphore(maxConcurrency: 3);
      final futures = List.generate(classBatches.length, (index) {
        return semaphore.run(() async {
          final batch = classBatches[index];
          final response = await _syncRemoteDataSource.fullSync(
            deviceId: deviceId,
            classIds: batch,
            receiveTimeout: const Duration(seconds: 30),
          );
          return MapEntry(index, response);
        });
      });
      final results = await Future.wait(futures);
      results.sort((a, b) => a.key.compareTo(b.key));

      // Upsert in original order so progress bar is deterministic
      for (final entry in results) {
        final batchIndex = entry.key;
        final batchResponse = entry.value;
        final batch = classBatches[batchIndex];

        const progressBase = 0.1;
        const progressRange = 0.85;
        final batchProgress = progressBase + (progressRange * (batchIndex / classBatches.length));

        // Create step description with batch titles
        final batchTitles = batch.map((id) => classMap[id] ?? id).join(' & ');
        final currentStepText = 'Getting $batchTitles ready… (${batchIndex + 1}/${classBatches.length})';
        _updateState(progress: batchProgress, currentStep: currentStepText);

        _log.batchStart(batchIndex, classBatches.length, batch);

        // Upsert all entities from batch response
        final assessments = batchResponse.assessments;
        final questions = batchResponse.questions;
        final assessmentSubmissions = batchResponse.assessmentSubmissions;
        final assignments = batchResponse.assignments;
        final assignmentSubmissions = batchResponse.assignmentSubmissions;
        final submissionFiles = batchResponse.submissionFiles;
        final learningMaterials = batchResponse.learningMaterials;
        final materialFiles = batchResponse.materialFiles;
        final assessmentStatistics = batchResponse.assessmentStatistics;
        final studentResults = batchResponse.studentResults;
        final gradeConfigs = batchResponse.gradeConfigs;
        final gradeItems = batchResponse.gradeItems;
        final gradeScores = batchResponse.gradeScores;
        final periodGrades = batchResponse.periodGrades;
        final tableOfSpecifications = batchResponse.tableOfSpecifications;
        final tosCompetencies = batchResponse.tosCompetencies;
        final activityLogs = batchResponse.activityLogs;

        // Extract enrolled_students and enrollments from batch (for full offline support)
        final batchParticipantUsers = batchResponse.enrolledStudents ?? <Map<String, dynamic>>[];
        final batchParticipants = batchResponse.enrollments;

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
          'grade_configs': gradeConfigs.length,
          'grade_items': gradeItems.length,
          'grade_scores': gradeScores.length,
          'period_grades': periodGrades.length,
          'table_of_specifications': tableOfSpecifications.length,
          'tos_competencies': tosCompetencies.length,
          'activity_logs': activityLogs.length,
          'enrolled_students': batchParticipantUsers.length,
          'enrollments': batchParticipants.length,
        });

        // Build submission count map (needed for mismatch detector below)
        final byAssessment = <String, int>{};
        if (assessmentSubmissions.isNotEmpty) {
          for (final s in assessmentSubmissions) {
            final aid = s['assessment_id']?.toString();
            if (aid != null) {
              byAssessment[aid] = (byAssessment[aid] ?? 0) + 1;
            }
          }
          _log.log('Assessment submissions by assessment: $byAssessment');
        }

        // Log questions per assessment
        final questionsByAssessment = <String, int>{};
        for (final q in questions) {
          final assessmentId = q['assessment_id'] as String?;
          if (assessmentId != null) {
            questionsByAssessment[assessmentId] = (questionsByAssessment[assessmentId] ?? 0) + 1;
          }
        }
        for (final assessment in assessments) {
          final assessmentId = assessment['id'] as String?;
          final title = assessment['title'] as String? ?? 'unknown';
          final qCount = questionsByAssessment[assessmentId] ?? 0;
          _log.questionsPerAssessment(title, assessmentId ?? '?', qCount);
        }

        // Detect potential truncation: submissions with answers but zero questions
        for (final assessment in assessments) {
          final assessmentId = assessment['id'] as String?;
          if (assessmentId == null) continue;
          final qCount = questionsByAssessment[assessmentId] ?? 0;
          final subCount = byAssessment[assessmentId] ?? 0;
          if (subCount > 0 && qCount == 0) {
            _log.warn('WARNING: Assessment $assessmentId has $subCount submissions but 0 questions — possible server truncation');
          }
        }

        // NEW: Upsert batch enrolled_students and enrollments (for full offline support)
        await db.transaction((txn) async {
          await _upsertHelpers.upsertEnrolledStudents(txn, batchParticipantUsers);
          await _upsertHelpers.upsertParticipants(txn, batchParticipants, batchParticipantUsers);

          // Update in-memory studentMap with batch students so submissions can reference them
          for (final s in batchParticipantUsers) {
            final id = s['id']?.toString();
            if (id != null && id.isNotEmpty) {
              studentMap[id] = s;
            }
          }

          await _upsertHelpers.upsertAssessments(txn, assessments);
          await _upsertHelpers.upsertQuestions(txn, questions);
          await _upsertHelpers.upsertAssessmentSubmissions(txn, assessmentSubmissions, studentMap);
          await _upsertHelpers.upsertAssignments(txn, assignments);
          await _upsertHelpers.upsertAssignmentSubmissions(txn, assignmentSubmissions, studentMap);
          await _upsertHelpers.upsertSubmissionFiles(txn, submissionFiles);
          await _upsertHelpers.upsertLearningMaterials(txn, learningMaterials);
          await _upsertHelpers.upsertMaterialFiles(txn, materialFiles);

          // Write student_results to cache
          await _upsertHelpers.upsertStudentResults(txn, studentResults);

          await _upsertHelpers.upsertGradeConfigs(txn, gradeConfigs);
          await _upsertHelpers.upsertGradeItems(txn, gradeItems);
          await _upsertHelpers.upsertGradeScores(txn, gradeScores);
          await _upsertHelpers.upsertPeriodGrades(txn, periodGrades);

          await _upsertHelpers.upsertTableOfSpecifications(txn, tableOfSpecifications);
          await _upsertHelpers.upsertTosCompetencies(txn, tosCompetencies);
          await _upsertHelpers.upsertActivityLogs(txn, activityLogs);

          await _upsertHelpers.upsertLearnerDetails(txn, batchResponse.learnerDetails);
          await _upsertHelpers.upsertAttendanceRecords(txn, batchResponse.attendanceRecords);
          await _upsertHelpers.upsertCoreValuesRecords(txn, batchResponse.coreValuesRecords);
          await _upsertHelpers.upsertStudentSchoolHistory(txn, batchResponse.studentSchoolHistory);
          await _upsertHelpers.upsertPreviousSchoolSubjects(txn, batchResponse.previousSchoolSubjects);
          await _upsertHelpers.upsertPreviousSchoolAttendance(txn, batchResponse.previousSchoolAttendance);
        });
      }
    } else if (!needsEntityBatches) {
      _log.warn('Skipping entity batches (server says none needed)');
    }

    await _upsertHelpers.recalculateClassStudentCounts(db);

    // Notify gradebook UIs that grades may have changed
    for (final classId in classMap.keys) {
      _dataEventBus.notifyGradesChanged(classId);
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
    await _upsertHelpers.saveSyncToken(db, syncToken);
    await _upsertHelpers.saveSyncExpiry(db, expiryAt);

    return serverTime;
  }

  /// Run delta sync on app restart
  /// Returns null if data_expired (caller should fall back to full sync)
  Future<String?> runDeltaSync(String lastSyncAt, String? dataExpiryAt) async {
    // Get device ID
    final db = await _localDatabase.database;
    final deviceId = await _getOrCreateDeviceId(db);

    // Fetch deltas
    final response =
        await _syncRemoteDataSource.deltaSync(
      deviceId: deviceId,
      lastSyncAt: lastSyncAt,
      dataExpiryAt: dataExpiryAt,
    );

    // Check if data is expired
    if (response.isExpired) {
      return null; // Caller will fall back to full sync
    }

    final syncToken = response.syncToken;
    final serverTime = response.serverTime;
    final deltas = response.deltas;

    if (syncToken == null || deltas == null) {
      _log.error('Missing fields in delta sync response', 'sync_token=$syncToken, deltas=$deltas');
      throw Exception('Invalid delta sync response: missing sync_token or deltas');
    }

    // Process deltas: upsert updated, delete removed
    await _upsertHelpers.processDeltaPayload(db, deltas.toJson());
    await _upsertHelpers.recalculateClassStudentCounts(db);

    // Notify gradebook UIs if grade_scores changed
    if (deltas.gradeScores.updated.isNotEmpty || deltas.gradeScores.deleted.isNotEmpty) {
      final gradeItemRows = await db.query(
        DbTables.gradeItems,
        columns: [GradeItemsCols.classId],
        distinct: true,
      );
      for (final row in gradeItemRows) {
        final classId = row[GradeItemsCols.classId] as String?;
        if (classId != null && classId.isNotEmpty) {
          _dataEventBus.notifyGradesChanged(classId);
        }
      }
    }

    // Signal that delta data is now merged into local DB
    _updateState(
      assessmentsReady: true,
      assignmentsReady: true,
      materialsReady: true,
    );

    // Update sync metadata
    final expiryAt = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    await _upsertHelpers.saveSyncToken(db, syncToken);
    await _upsertHelpers.saveSyncExpiry(db, expiryAt);

    return serverTime ?? syncToken;
  }

  /// Get existing device ID or generate and store a new one
  Future<String> _getOrCreateDeviceId(Database db) async {
    final rows = await db.query(
      DbTables.syncMetadata,
      where: '${SyncMetadataCols.key} = ?',
      whereArgs: [DbValues.metaDeviceId],
    );
    return rows.isNotEmpty
        ? rows.first[SyncMetadataCols.value] as String
        : await generateAndStoreDeviceId(db);
  }

  /// Generate and store a device ID
  Future<String> generateAndStoreDeviceId(Database db) async {
    final deviceId = const Uuid().v4();
    await db.insert(
      DbTables.syncMetadata,
      {SyncMetadataCols.key: DbValues.metaDeviceId, SyncMetadataCols.value: deviceId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return deviceId;
  }
}
