import 'dart:io';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/core/sync/handlers/assessment_sync_handler.dart';
import 'package:likha/core/sync/handlers/assignment_sync_handler.dart';
import 'package:likha/core/sync/handlers/auth_sync_handler.dart';
import 'package:likha/core/sync/handlers/class_sync_handler.dart';
import 'package:likha/core/sync/handlers/grading_sync_handler.dart';
import 'package:likha/core/sync/handlers/learning_material_sync_handler.dart';
import 'package:likha/core/sync/handlers/setup_sync_handler.dart';
import 'package:likha/core/sync/handlers/student_records_sync_handler.dart';
import 'package:likha/core/sync/handlers/tos_sync_handler.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_state.dart';
import 'package:likha/data/datasources/remote/sync/sync_remote_datasource.dart';
import 'package:likha/data/models/sync/push_response_model.dart';

/// Maps a [SyncEntityType.serverValue] string to its local DB table name.
/// Returns null for entity types that do not have a standalone table row to update.
String? _entityTypeToTable(String entityType) {
  switch (entityType) {
    case 'assignment': return DbTables.assignments;
    case 'class': return DbTables.classes;
    case 'assessment': return DbTables.assessments;
    case 'question': return DbTables.assessmentQuestions;
    case 'assignment_submission': return DbTables.assignmentSubmissions;
    case 'assessment_submission': return DbTables.assessmentSubmissions;
    case 'submission_file': return DbTables.submissionFiles;
    case 'material_file': return DbTables.materialFiles;
    case 'learning_material': return DbTables.learningMaterials;
    case 'grade_item': return DbTables.gradeItems;
    case 'grade_score': return DbTables.gradeScores;
    case 'grade_config': return DbTables.gradeRecord;
    case 'table_of_specifications': return DbTables.tableOfSpecifications;
    case 'tos_competency': return DbTables.tosCompetencies;
    case 'admin_user': return DbTables.users;
    case 'school_details': return DbTables.schoolDetails;
    case 'learner_details': return DbTables.learnerDetails;
    case 'attendance_records': return DbTables.attendanceRecords;
    case 'core_values_records': return DbTables.coreValuesRecords;
    case 'school_history': return DbTables.studentSchoolHistory;
    case 'previous_school_subjects': return DbTables.previousSchoolSubjects;
    case 'previous_school_term_grades': return DbTables.previousSchoolTermGrades;
    case 'previous_school_attendance': return DbTables.previousSchoolAttendance;
    default: return null;
  }
}

class OutboundSyncHandler {
  final SyncQueue _syncQueue;
  final SyncRemoteDataSource _syncRemoteDataSource;
  final LocalDatabase _localDatabase;
  final SyncLogger _log;
  final SyncStateUpdater _updateState;
  final AssessmentSyncHandler? _assessmentHandler;
  final AssignmentSyncHandler? _assignmentHandler;
  final AuthSyncHandler? _authHandler;
  final ClassSyncHandler? _classHandler;
  final GradingSyncHandler? _gradingHandler;
  final LearningMaterialSyncHandler? _learningMaterialHandler;
  final TosSyncHandler? _tosHandler;
  final SetupSyncHandler? _setupHandler;
  final StudentRecordsSyncHandler? _studentRecordsHandler;

  OutboundSyncHandler(
    this._syncQueue,
    this._syncRemoteDataSource,
    this._localDatabase,
    this._log,
    this._updateState, {
    AssessmentSyncHandler? assessmentHandler,
    AssignmentSyncHandler? assignmentHandler,
    AuthSyncHandler? authHandler,
    ClassSyncHandler? classHandler,
    GradingSyncHandler? gradingHandler,
    LearningMaterialSyncHandler? learningMaterialHandler,
    TosSyncHandler? tosHandler,
    SetupSyncHandler? setupHandler,
    StudentRecordsSyncHandler? studentRecordsHandler,
  })  : _assessmentHandler = assessmentHandler,
        _assignmentHandler = assignmentHandler,
        _authHandler = authHandler,
        _classHandler = classHandler,
        _gradingHandler = gradingHandler,
        _learningMaterialHandler = learningMaterialHandler,
        _tosHandler = tosHandler,
        _setupHandler = setupHandler,
        _studentRecordsHandler = studentRecordsHandler;

  Future<void> _handleRetry(SyncQueueEntry op) async {
    await _syncQueue.incrementRetry(op.id);
    final updated = await _syncQueue.getById(op.id);
    if (updated != null && updated.retryCount >= updated.maxRetries) {
      _log.log('Retry exhausted for ${op.entityType.dbValue}.${op.operation.dbValue} (${op.id}), marking failed');
      await _syncQueue.markFailed(op.id, 'Max retries exceeded');
    }
  }

  Future<void> outboundSync() async {
    _log.log('outboundSync() - START');
    
    final pending = await _syncQueue.getAllRetriable();
    _log.log('Found ${pending.length} pending operations');
    
    if (pending.isEmpty) {
      _log.log('No pending operations, returning');
      return;
    }
    
    // Log all pending operations for debugging
    for (final op in pending) {
      _log.log('Pending op: ${op.entityType}.${op.operation} (${op.id}) - status: ${op.status}');
    }

    // PASS 0: Process assessmentSubmission creates FIRST so dependent ops
    // (submit) can reference the real server-assigned ID.
    final assessmentSubmissionCreates = pending
        .where((e) =>
            e.entityType == SyncEntityType.assessmentSubmission &&
            e.operation == SyncOperation.create)
        .toList();

    if (assessmentSubmissionCreates.isNotEmpty) {
      await syncAssessmentSubmissionCreates(assessmentSubmissionCreates);
    }

    // Re-fetch after reconciliation — creates are now 'succeeded',
    // remaining pending entries have updated submission_ids in their payloads.
    var remaining = await _syncQueue.getAllRetriable();
    if (remaining.isEmpty) return;

    // PASS 1: Process assignmentSubmission creates so dependent ops
    // (submit, file uploads) can reference the real server-assigned ID.
    final assignmentSubmissionCreates = remaining
        .where((e) =>
            e.entityType == SyncEntityType.assignmentSubmission &&
            e.operation == SyncOperation.create)
        .toList();

    if (assignmentSubmissionCreates.isNotEmpty) {
      await syncAssignmentSubmissionCreates(assignmentSubmissionCreates);
    }

    // Re-fetch after reconciliation — creates are now 'succeeded',
    // remaining pending entries have updated submission_ids in their payloads.
    remaining = await _syncQueue.getAllRetriable();
    if (remaining.isEmpty) return;

    // Existing bucket-based logic (unchanged):
    final nonMaterialFileUploads = remaining
        .where((e) => e.operation == SyncOperation.upload &&
                    e.entityType != SyncEntityType.materialFile)
        .toList();
    final materialFileUploads = remaining
        .where((e) => e.operation == SyncOperation.upload &&
                    e.entityType == SyncEntityType.materialFile)
        .toList();
    final regularOps = remaining
        .where((e) => e.operation != SyncOperation.upload)
        .toList();

    // Route assessment operations to the dedicated handler.
    final assessmentOps = regularOps
        .where((e) => e.entityType == SyncEntityType.assessment)
        .toList();
    if (assessmentOps.isNotEmpty && _assessmentHandler != null) {
      _log.log('Processing ${assessmentOps.length} assessment ops via handler');
      for (final op in assessmentOps) {
        final result = await _assessmentHandler.handle(op);
        if (result.success) {
          await _syncQueue.markSucceeded(op.id);
        } else if (result.shouldRetry) {
          await _handleRetry(op);
        } else {
          await _syncQueue.markFailed(op.id, result.error ?? 'Unknown error');
        }
      }
    }

    // Route grading operations to the dedicated handler.
    final gradingOps = regularOps
        .where((e) =>
            e.entityType == SyncEntityType.gradeConfig ||
            e.entityType == SyncEntityType.gradeItem ||
            e.entityType == SyncEntityType.gradeScore)
        .toList();
    if (gradingOps.isNotEmpty && _gradingHandler != null) {
      _log.log('Processing ${gradingOps.length} grading ops via handler');
      for (final op in gradingOps) {
        final result = await _gradingHandler.handle(op);
        if (result.success) {
          await _syncQueue.markSucceeded(op.id);
        } else if (result.shouldRetry) {
          await _handleRetry(op);
        } else {
          await _syncQueue.markFailed(op.id, result.error ?? 'Unknown error');
        }
      }
    }

    // Route learning material operations to the dedicated handler.
    final learningMaterialOps = regularOps
        .where((e) =>
            e.entityType == SyncEntityType.learningMaterial ||
            e.entityType == SyncEntityType.materialFile)
        .toList();
    if (learningMaterialOps.isNotEmpty && _learningMaterialHandler != null) {
      _log.log('Processing ${learningMaterialOps.length} learning material ops via handler');
      for (final op in learningMaterialOps) {
        final result = await _learningMaterialHandler.handle(op);
        if (result.success) {
          await _syncQueue.markSucceeded(op.id);
        } else if (result.shouldRetry) {
          await _handleRetry(op);
        } else {
          await _syncQueue.markFailed(op.id, result.error ?? 'Unknown error');
        }
      }
    }

    // Route TOS operations to the dedicated handler.
    final tosOps = regularOps
        .where((e) =>
            e.entityType == SyncEntityType.tableOfSpecifications ||
            e.entityType == SyncEntityType.tosCompetency)
        .toList();
    if (tosOps.isNotEmpty && _tosHandler != null) {
      _log.log('Processing ${tosOps.length} TOS ops via handler');
      for (final op in tosOps) {
        final result = await _tosHandler.handle(op);
        if (result.success) {
          await _syncQueue.markSucceeded(op.id);
        } else if (result.shouldRetry) {
          await _handleRetry(op);
        } else {
          await _syncQueue.markFailed(op.id, result.error ?? 'Unknown error');
        }
      }
    }

    // Route class operations to the dedicated handler.
    final classOps = regularOps
        .where((e) => e.entityType == SyncEntityType.classEntity)
        .toList();
    if (classOps.isNotEmpty && _classHandler != null) {
      _log.log('Processing ${classOps.length} class ops via handler');
      for (final op in classOps) {
        final result = await _classHandler.handle(op);
        if (result.success) {
          await _syncQueue.markSucceeded(op.id);
        } else if (result.shouldRetry) {
          await _handleRetry(op);
        } else {
          await _syncQueue.markFailed(op.id, result.error ?? 'Unknown error');
        }
      }
    }

    // Route auth operations to the dedicated handler.
    final authOps = regularOps
        .where((e) => e.entityType == SyncEntityType.adminUser)
        .toList();
    if (authOps.isNotEmpty && _authHandler != null) {
      _log.log('Processing ${authOps.length} auth ops via handler');
      for (final op in authOps) {
        final result = await _authHandler.handle(op);
        if (result.success) {
          await _syncQueue.markSucceeded(op.id);
        } else if (result.shouldRetry) {
          await _handleRetry(op);
        } else {
          await _syncQueue.markFailed(op.id, result.error ?? 'Unknown error');
        }
      }
    }

    // Route assignment operations to the dedicated handler.
    final assignmentOps = regularOps
        .where((e) =>
            e.entityType == SyncEntityType.assignment ||
            e.entityType == SyncEntityType.assignmentSubmission)
        .toList();
    if (assignmentOps.isNotEmpty && _assignmentHandler != null) {
      _log.log('Processing ${assignmentOps.length} assignment ops via handler');
      for (final op in assignmentOps) {
        final result = await _assignmentHandler.handle(op);
        if (result.success) {
          await _syncQueue.markSucceeded(op.id);
        } else if (result.shouldRetry) {
          await _handleRetry(op);
        } else {
          await _syncQueue.markFailed(op.id, result.error ?? 'Unknown error');
        }
      }
    }

    // Route setup operations to the dedicated handler.
    final setupOps = regularOps
        .where((e) => e.entityType == SyncEntityType.schoolDetails)
        .toList();
    if (setupOps.isNotEmpty && _setupHandler != null) {
      _log.log('Processing ${setupOps.length} setup ops via handler');
      for (final op in setupOps) {
        final result = await _setupHandler.handle(op);
        if (result.success) {
          await _syncQueue.markSucceeded(op.id);
        } else if (result.shouldRetry) {
          await _handleRetry(op);
        } else {
          await _syncQueue.markFailed(op.id, result.error ?? 'Unknown error');
        }
      }
    }

    // Route student records operations to the dedicated handler.
    final studentRecordsOps = regularOps
        .where((e) =>
            e.entityType == SyncEntityType.learnerDetails ||
            e.entityType == SyncEntityType.attendanceRecords ||
            e.entityType == SyncEntityType.coreValuesRecords ||
            e.entityType == SyncEntityType.schoolHistory ||
            e.entityType == SyncEntityType.previousSchoolSubjects ||
            e.entityType == SyncEntityType.previousSchoolTermGrades ||
            e.entityType == SyncEntityType.previousSchoolAttendance)
        .toList();
    if (studentRecordsOps.isNotEmpty && _studentRecordsHandler != null) {
      _log.log('Processing ${studentRecordsOps.length} student_records ops via handler');
      for (final op in studentRecordsOps) {
        final result = await _studentRecordsHandler.handle(op);
        if (result.success) {
          await _syncQueue.markSucceeded(op.id);
        } else if (result.shouldRetry) {
          await _handleRetry(op);
        } else {
          await _syncQueue.markFailed(op.id, result.error ?? 'Unknown error');
        }
      }
    }

    final nonAssessmentOps = regularOps
        .where((e) =>
            e.entityType != SyncEntityType.assessment &&
            e.entityType != SyncEntityType.assignment &&
            e.entityType != SyncEntityType.assignmentSubmission &&
            e.entityType != SyncEntityType.classEntity &&
            e.entityType != SyncEntityType.adminUser &&
            e.entityType != SyncEntityType.gradeConfig &&
            e.entityType != SyncEntityType.gradeItem &&
            e.entityType != SyncEntityType.gradeScore &&
            e.entityType != SyncEntityType.learningMaterial &&
            e.entityType != SyncEntityType.materialFile &&
            e.entityType != SyncEntityType.tableOfSpecifications &&
            e.entityType != SyncEntityType.tosCompetency &&
            e.entityType != SyncEntityType.schoolDetails &&
            e.entityType != SyncEntityType.learnerDetails &&
            e.entityType != SyncEntityType.attendanceRecords &&
            e.entityType != SyncEntityType.coreValuesRecords &&
            e.entityType != SyncEntityType.schoolHistory &&
            e.entityType != SyncEntityType.previousSchoolSubjects &&
            e.entityType != SyncEntityType.previousSchoolTermGrades &&
            e.entityType != SyncEntityType.previousSchoolAttendance)
        .toList();

    _log.log('Found ${nonAssessmentOps.length} regular operations');

    final opsByType = <String, int>{};
    for (final op in nonAssessmentOps) {
      opsByType[op.entityType.serverValue] = (opsByType[op.entityType.serverValue] ?? 0) + 1;
      if (op.entityType == SyncEntityType.gradeScore) {
        _log.log('Grade score operation: ${op.operation} (${op.id})');
      }
    }

    _log.log('Operations by type: $opsByType');

    _log.pushStarting(
      uploadOpsCount: nonMaterialFileUploads.length + materialFileUploads.length,
      regularOpsCount: nonAssessmentOps.length,
      operationsByType: opsByType,
    );

    final pushStartTime = DateTime.now();

    // Step 1: Run non-material file uploads first (submission files, etc.)
    for (final op in nonMaterialFileUploads) {
      await handleFileUpload(op);
    }

    // Step 2: Run all regular operations in one batch
    if (nonAssessmentOps.isNotEmpty) {
      await syncRegularBatch(nonAssessmentOps, pushStartTime);
    }

    // Step 3: Run material file uploads AFTER regular ops (material now exists on server)
    for (final op in materialFileUploads) {
      await handleFileUpload(op);
    }
  }

  /// Process assessmentSubmission creates first and reconcile local IDs with server IDs
  Future<void> syncAssessmentSubmissionCreates(
      List<SyncQueueEntry> createOps) async {
    final operations = createOps.map((entry) => {
      'id':          entry.id,
      'entity_type': entry.entityType.serverValue,
      'operation':   entry.operation.serverValue,
      'payload':     entry.payload,
    }).toList();

    final response =
        await _syncRemoteDataSource.pushOperations(operations: operations);

    final db = await _localDatabase.database;

    for (final result in response.results) {
      if (result.success) {
        final entry = createOps.firstWhere((e) => e.id == result.id);
        final localId = entry.payload['id'] as String?;
        final serverId = result.serverId;

        if (localId != null && serverId != null && localId != serverId) {
          // Reconcile assessment_submissions table
          await db.update(
            DbTables.assessmentSubmissions,
            {CommonCols.id: serverId},
            where: '${CommonCols.id} = ?',
            whereArgs: [localId],
          );

          // Rewrite submission_id in all remaining pending queue entries
          // (covers submit op + save_answers op referencing the local UUID)
          await _syncQueue.updatePendingSubmissionIds(localId, serverId);
        }

        await _syncQueue.markSucceeded(result.id);
      } else {
        await _syncQueue.markFailed(result.id, result.error ?? 'Unknown error');
      }
    }
  }

  /// Process assignmentSubmission creates first and reconcile local IDs with server IDs
  Future<void> syncAssignmentSubmissionCreates(
      List<SyncQueueEntry> createOps) async {
    final operations = createOps.map((entry) => {
      'id':          entry.id,
      'entity_type': entry.entityType.serverValue,
      'operation':   entry.operation.serverValue,
      'payload':     entry.payload,
    }).toList();

    final response =
        await _syncRemoteDataSource.pushOperations(operations: operations);

    final db = await _localDatabase.database;

    for (final result in response.results) {
      if (result.success) {
        final entry = createOps.firstWhere((e) => e.id == result.id);
        final localId = entry.payload['id'] as String?;
        final serverId = result.serverId;

        if (localId != null && serverId != null && localId != serverId) {
          // Reconcile assignment_submissions table
          await db.update(
            DbTables.assignmentSubmissions,
            {CommonCols.id: serverId},
            where: '${CommonCols.id} = ?',
            whereArgs: [localId],
          );

          // Reconcile submission_files staged under the local submission ID
          await db.update(
            DbTables.submissionFiles,
            {SubmissionFilesCols.submissionId: serverId},
            where: "${SubmissionFilesCols.submissionId} = ? AND ${CommonCols.syncStatus} = '${SyncStatus.pending.dbValue}'",
            whereArgs: [localId],
          );

          // Rewrite submission_id in all remaining pending queue entries
          // (covers submit op + file upload ops referencing the local UUID)
          await _syncQueue.updatePendingSubmissionIds(localId, serverId);
        }

        await _syncQueue.markSucceeded(result.id);
      } else {
        await _syncQueue.markFailed(result.id, result.error ?? 'Unknown error');
      }
    }
  }

  /// Sync a batch of operations
  Future<void> syncRegularBatch(List<SyncQueueEntry> regularOps, DateTime pushStartTime) async {
    _updateState(pendingCount: regularOps.length);

    final operations = regularOps.map((entry) {
      return {
        'id':          entry.id,
        'entity_type': entry.entityType.serverValue,
        'operation':   entry.operation.serverValue,
        'payload':     entry.payload,
      };
    }).toList();

    try {
      final response = await _syncRemoteDataSource.pushOperations(
        operations: operations,
      );
      await processPushResults(response, pushStartTime);
    } on NetworkException catch (_) {
      for (final op in regularOps) {
        await _handleRetry(op);
      }
      rethrow;
    }
  }

  /// Process push results and update local state
  Future<void> processPushResults(PushResponseModel response, DateTime startTime) async {
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
                DbTables.classes,
                {CommonCols.id: serverId},
                where: '${CommonCols.id} = ?',
                whereArgs: [payloadId],
              );
            } else if (entityType == SyncEntityType.gradeItem.serverValue) {
              // Reconcile grade_item ID
              await db.update(
                DbTables.gradeItems,
                {CommonCols.id: serverId},
                where: '${CommonCols.id} = ?',
                whereArgs: [payloadId],
              );
              // Update any grade_scores referencing the old grade_item_id
              await db.update(
                DbTables.gradeScores,
                {GradeScoresCols.gradeItemId: serverId},
                where: '${GradeScoresCols.gradeItemId} = ?',
                whereArgs: [payloadId],
              );
            } else if (entityType == SyncEntityType.assignment.serverValue) {
              await db.update(
                DbTables.assignments,
                {CommonCols.id: serverId},
                where: '${CommonCols.id} = ?',
                whereArgs: [payloadId],
              );
            }
          }
        }

        // Update entity row sync_status → synced
        final entityId = serverId ?? entry?.payload['id'] as String?;
        final table = _entityTypeToTable(entityType);
        if (table != null && entityId != null) {
          await db.update(
            table,
            {CommonCols.syncStatus: SyncStatus.synced.dbValue},
            where: '${CommonCols.id} = ?',
            whereArgs: [entityId],
          );
        }

        // Mark as succeeded and remove from queue
        await _syncQueue.markSucceeded(opId);
      } else {
        failedByType[entityType] = (failedByType[entityType] ?? 0) + 1;

        // Mark as failed and write sync_status → failed on entity row
        final error = result.error ?? 'Unknown error';
        final failEntry = await _syncQueue.getById(opId);
        final failEntityId = failEntry?.payload['id'] as String?;
        final failTable = _entityTypeToTable(entityType);
        if (failTable != null && failEntityId != null) {
          await db.update(
            failTable,
            {CommonCols.syncStatus: SyncStatus.failed.dbValue},
            where: '${CommonCols.id} = ?',
            whereArgs: [failEntityId],
          );
        }
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

  /// Handles a single file upload operation by calling the multipart endpoint directly.
  /// References pattern in: mobile/lib/data/datasources/remote/assignments/assignment_remote_datasource.dart
  /// For material files, looks up correct (reconciled) material_id from DB instead of using payload.
  Future<void> handleFileUpload(SyncQueueEntry op) async {
    try {
      final payload      = op.payload;
      final localPath    = payload['local_path']    as String;
      final fileName     = payload['file_name']     as String;
      final fileId       = payload['file_id']       as String?;
      final submissionId = payload['submission_id'] as String?;
      var materialId     = payload['material_id']   as String?;

      _log.log('handleFileUpload: op_id=${op.id.substring(0, 8)} file=$fileName file_id=${fileId?.substring(0, 8) ?? "none"}');

      // For material file uploads, look up the correct (reconciled) material_id from DB
      if (materialId != null && fileId != null) {
        try {
          final db = await _localDatabase.database;
          final rows = await db.query(
            DbTables.materialFiles,
            columns: [MaterialFilesCols.materialId],
            where: '${CommonCols.id} = ?',
            whereArgs: [fileId],
          );
          if (rows.isNotEmpty) {
            final reconciledMaterialId = rows.first[MaterialFilesCols.materialId] as String?;
            if (reconciledMaterialId != materialId) {
              _log.log('handleFileUpload: reconciled material_id ${materialId.substring(0, 8)} → ${reconciledMaterialId?.substring(0, 8)}');
              materialId = reconciledMaterialId;
            }
          }
        } catch (e) {
          _log.error('handleFileUpload: failed to look up reconciled material_id - $e');
          // If DB lookup fails, fall back to payload value
        }
      }

      if (submissionId != null) {
        final response = await _syncRemoteDataSource.uploadSubmissionFile(
          submissionId: submissionId,
          localPath: localPath,
          fileName: fileName,
        );

        // Fix 3: Reconcile server file ID with local UUID
        if (response != null && fileId != null) {
          final serverId = response['id'] as String?;
          if (serverId != null && serverId != fileId) {
            try {
              final db = await _localDatabase.database;
              // Rename row ID from local UUID to server UUID
              await db.update(
                DbTables.submissionFiles,
                {
                  CommonCols.id: serverId,
                  SubmissionFilesCols.localPath: '',
                },
                where: '${CommonCols.id} = ?',
                whereArgs: [fileId],
              );
            } catch (e) {
              _log.error('Failed to reconcile file ID: $e');
              // Continue — file is on server even if local reconciliation fails
            }
          }
        }
      } else if (materialId != null) {
        _log.log('handleFileUpload: uploading material file material_id=${materialId.substring(0, 8)}');
        final response = await _syncRemoteDataSource.uploadMaterialFile(
          materialId: materialId,
          localPath: localPath,
          fileName: fileName,
          idempotencyKey: op.id,
        );

        // Reconcile server file ID and clear local path
        if (fileId != null) {
          try {
            final db = await _localDatabase.database;
            final updates = <String, dynamic>{
              MaterialFilesCols.localPath: '',
              CommonCols.syncStatus: SyncStatus.synced.dbValue,
            };
            final serverId = response?['id'] as String?;
            if (serverId != null && serverId != fileId) {
              _log.log('handleFileUpload: reconciling file_id ${fileId.substring(0, 8)} → ${serverId.substring(0, 8)}');
              updates[CommonCols.id] = serverId;
            }
            await db.update(
              DbTables.materialFiles,
              updates,
              where: '${CommonCols.id} = ?',
              whereArgs: [fileId],
            );
            _log.log('handleFileUpload: DB updated: syncStatus=synced, localPath cleared');
          } catch (e) {
            _log.error('handleFileUpload: failed to reconcile material file - $e');
          }
        }
      }

      // Clean up staged file after successful upload
      try {
        final stagedFile = File(localPath);
        if (await stagedFile.exists()) {
          _log.log('handleFileUpload: deleting staged file $localPath');
          await stagedFile.delete();
        }
      } catch (e) {
        _log.warn('handleFileUpload: failed to delete staged file - $e');
        // Log but don't fail sync if cleanup fails
      }

      _log.log('handleFileUpload: marking queue entry ${op.id.substring(0, 8)} as succeeded');
      await _syncQueue.markSucceeded(op.id);
    } on NetworkException catch (e) {
      _log.error('handleFileUpload: network error, incrementing retry - ${e.message}');
      await _handleRetry(op);
      rethrow;
    } catch (e) {
      _log.error('handleFileUpload: failed, marking as failed - $e');
      await _syncQueue.markFailed(op.id, e.toString());
    }
  }
}
